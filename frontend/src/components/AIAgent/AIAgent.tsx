import { useState, useEffect, useRef } from 'react';
import { getCalories, recommendBurgerForCalories } from '../../utils/calorieData';

interface Message {
  role: 'user' | 'agent';
  text: string;
}

interface Props {
  ingredients: { id: number; name: string }[];
  onAddToCart: (ingredientId: number) => void;
}

export const AIAgent = ({ ingredients, onAddToCart }: Props) => {
  const [open, setOpen] = useState(true);
  const [messages, setMessages] = useState<Message[]>([
    { role: 'agent', text: 'Hello! I am Burger AI 🍔 I can help you order burgers or recommend ingredients based on calories! Try saying "I need a burger with 500 calories"' }
  ]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [listening, setListening] = useState(false);
  const [voiceMode, setVoiceMode] = useState(true);
  const recognitionRef = useRef<any>(null);

  const speak = (text: string, onDone?: () => void) => {
    if (!voiceMode) { onDone?.(); return; }
    
    try {
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.lang = 'en-US';
      utterance.onend = () => onDone?.();
      utterance.onerror = () => onDone?.();
      window.speechSynthesis.speak(utterance);
    } catch {
      onDone?.();
    }
  };

  const startListening = () => {
    if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
      setMessages(prev => [...prev, { role: 'agent', text: 'Voice input not supported in this browser. Please use text input.' }]);
      return;
    }

    try {
      const SpeechRecognition = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;
      const recognition = new SpeechRecognition();
      recognition.lang = 'en-US';
      recognition.continuous = false;
      recognition.interimResults = false;

      recognition.onresult = (event: any) => {
        const transcript = event.results[0][0].transcript;
        setInput(transcript);
        sendMessage(transcript);
        setListening(false);
      };

      recognition.onerror = (event: any) => {
        console.error('Speech recognition error:', event.error);
        setMessages(prev => [...prev, { role: 'agent', text: 'Could not hear you. Please try again.' }]);
        setListening(false);
      };

      recognition.onend = () => {
        setListening(false);
      };

      recognitionRef.current = recognition;
      recognition.start();
      setListening(true);
    } catch (error) {
      console.error('Speech recognition error:', error);
      setMessages(prev => [...prev, { role: 'agent', text: 'Microphone access denied. Please use text input.' }]);
      setListening(false);
    }
  };

  const stopListening = () => {
    recognitionRef.current?.stop();
    setListening(false);
  };

  useEffect(() => {
    if (voiceMode) {
      setTimeout(() => {
        speak('Hello! I am Burger AI. I can help you order burgers or recommend ingredients based on calories!', () => {
          startListening();
        });
      }, 1000);
    }
  }, []);

  const extractCaloriesFromText = (text: string): number | null => {
    const calorieMatch = text.match(/(\d+)\s*(?:calories?|kcal|cal)/i);
    return calorieMatch ? parseInt(calorieMatch[1]) : null;
  };

  const handleCalorieRequest = (targetCalories: number): string => {
    const recommended = recommendBurgerForCalories(ingredients, targetCalories);
    
    if (recommended.length === 0) {
      return `Sorry, I couldn't find ingredients to make a ${targetCalories} calorie burger. Try a different calorie target.`;
    }

    const totalCalories = recommended.reduce((sum: number, ing: { calories: number }) => sum + ing.calories, 0);
    const ingredientList = recommended.map((ing: { name: string; calories: number }) => `${ing.name} (${ing.calories} cal)`).join(', ');

    // Auto-add ingredients to cart
    recommended.forEach((ing: { id: number }) => onAddToCart(ing.id));

    return `Great! For ${targetCalories} calories, I recommend: ${ingredientList}. Total: ${totalCalories} calories. I've added these ingredients to your burger! 🍔`;
  };

  const sendMessage = async (text: string) => {
    if (!text.trim()) return;
    setMessages(prev => [...prev, { role: 'user', text }]);
    setInput('');
    setLoading(true);
    setListening(false);

    try {
      // Check if user is asking about calories
      const calorieTarget = extractCaloriesFromText(text);
      
      if (calorieTarget) {
        const reply = handleCalorieRequest(calorieTarget);
        setMessages(prev => [...prev, { role: 'agent', text: reply }]);
        try {
          speak(reply, () => {
            if (voiceMode) startListening();
          });
        } catch {
          // Silently ignore speech errors
        }
        setLoading(false);
        return;
      }

      const endpoint = import.meta.env.VITE_AZURE_OPENAI_ENDPOINT;
      const apiKey = import.meta.env.VITE_AZURE_OPENAI_KEY;
      const url = `${endpoint}openai/deployments/gpt-4o-mini/chat/completions?api-version=2024-02-15-preview`;

      const menuList = ingredients.length > 0
        ? ingredients.map(i => `${i.name} (${getCalories(i.name)} cal)`).join(', ')
        : 'classic burgers, veggie burgers, cheese burgers, chicken burgers, fries, drinks';

      const res = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'api-key': apiKey,
        },
        body: JSON.stringify({
          max_tokens: 250,
          messages: [
            {
              role: 'system',
              content: `You are a friendly AI assistant for Burger Builder restaurant. 
              Help customers choose and build their perfect burger order. 
              Available menu items with calories: ${menuList}. 
              If user asks about calories, suggest specific ingredients that match their request.
              Keep responses short, friendly and helpful. Max 2-3 sentences.`
            },
            { role: 'user', content: text }
          ]
        }),
      });

      const data = await res.json() as {
        choices: { message: { content: string } }[]
      };
      const reply = data.choices[0].message.content;
      setMessages(prev => [...prev, { role: 'agent', text: reply }]);
      try {
        speak(reply, () => {
          if (voiceMode) startListening();
        });
      } catch {
        // Silently ignore speech errors
      }
    } catch {
      setMessages(prev => [...prev, { role: 'agent', text: 'Something went wrong, please try again.' }]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ position: 'fixed', bottom: '24px', right: '24px', zIndex: 1000, fontFamily: 'sans-serif' }}>
      {open && (
        <div style={{
          width: '340px', background: '#fff', borderRadius: '16px',
          boxShadow: '0 8px 32px rgba(0,0,0,0.18)',
          display: 'flex', flexDirection: 'column', overflow: 'hidden',
          marginBottom: '12px'
        }}>
          <div style={{
            background: '#e63946', padding: '14px 18px', color: '#fff',
            display: 'flex', justifyContent: 'space-between', alignItems: 'center'
          }}>
            <div>
              <strong>🍔 Burger AI Agent</strong>
              <p style={{ margin: '2px 0 0', fontSize: '12px', opacity: 0.85 }}>
                {listening ? '🎤 Listening...' : 'Type or speak your order'}
              </p>
            </div>
            <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
              <button
                onClick={() => { setVoiceMode(prev => { if (prev) stopListening(); return !prev; }); }}
                style={{
                  background: voiceMode ? 'rgba(255,255,255,0.3)' : 'rgba(0,0,0,0.2)',
                  border: 'none', borderRadius: '8px', color: '#fff',
                  fontSize: '14px', padding: '4px 8px', cursor: 'pointer'
                }}
              >{voiceMode ? '🔊' : '🔇'}</button>
              <button
                onClick={() => { stopListening(); setOpen(false); }}
                style={{ background: 'none', border: 'none', color: '#fff', fontSize: '20px', cursor: 'pointer' }}
              >×</button>
            </div>
          </div>

          <div style={{ height: '280px', overflowY: 'auto', padding: '12px', background: '#f9f9f9' }}>
            {messages.map((msg, i) => (
              <div key={i} style={{
                display: 'flex',
                justifyContent: msg.role === 'user' ? 'flex-end' : 'flex-start',
                marginBottom: '8px'
              }}>
                <div style={{
                  maxWidth: '80%', padding: '8px 12px', borderRadius: '12px',
                  background: msg.role === 'user' ? '#e63946' : '#fff',
                  color: msg.role === 'user' ? '#fff' : '#333',
                  fontSize: '13px', boxShadow: '0 1px 4px rgba(0,0,0,0.1)'
                }}>{msg.text}</div>
              </div>
            ))}
            {loading && <div style={{ textAlign: 'center', fontSize: '12px', color: '#999' }}>Thinking...</div>}
            {listening && <div style={{ textAlign: 'center', fontSize: '12px', color: '#e63946', fontWeight: 600 }}>🎤 Listening... speak now</div>}
          </div>

          <div style={{ display: 'flex', padding: '10px', gap: '6px', borderTop: '1px solid #eee' }}>
            <input
              value={input}
              onChange={e => setInput(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && sendMessage(input)}
              placeholder="E.g: I need 500 calories..."
              style={{ flex: 1, padding: '8px 12px', borderRadius: '8px', border: '1px solid #ddd', fontSize: '13px', outline: 'none' }}
            />
            <button
              onClick={listening ? stopListening : startListening}
              style={{
                padding: '8px 10px', borderRadius: '8px',
                background: listening ? '#e63946' : '#f0f0f0',
                border: 'none', cursor: 'pointer', fontSize: '16px',
                boxShadow: listening ? '0 0 0 3px rgba(230,57,70,0.3)' : 'none'
              }}
            >🎤</button>
            <button
              onClick={() => sendMessage(input)}
              style={{ padding: '8px 12px', borderRadius: '8px', background: '#e63946', color: '#fff', border: 'none', cursor: 'pointer', fontSize: '13px' }}
            >→</button>
          </div>
        </div>
      )}

      {!open && (
        <button
          onClick={() => setOpen(true)}
          style={{
            width: '56px', height: '56px', borderRadius: '50%',
            background: '#e63946', color: '#fff', border: 'none',
            fontSize: '24px', cursor: 'pointer',
            boxShadow: '0 4px 16px rgba(230,57,70,0.4)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}
          onMouseEnter={e => (e.currentTarget.style.transform = 'scale(1.1)')}
          onMouseLeave={e => (e.currentTarget.style.transform = 'scale(1)')}
        >🍔</button>
      )}
    </div>
  );
};

export default AIAgent;
