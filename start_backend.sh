#!/bin/bash
# Запустить этой командой: bash start_backend.sh YOUR_SQL_USER YOUR_SQL_PASS

SQL_USER=$1
SQL_PASS=$2

az vmss run-command invoke \
  -g musa-project2-rg \
  -n burger-vmss-be-musa \
  --command-id RunShellScript \
  --scripts "nohup sudo java -jar /home/azureuser/app.jar \
    --spring.datasource.url='jdbc:sqlserver://burger-sqlserver.database.windows.net:1433;database=burgerbuilder-group22;encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;' \
    --spring.datasource.username='${SQL_USER}' \
    --spring.datasource.password='${SQL_PASS}' \
    --server.port=8080 \
    > /home/azureuser/app.log 2>&1 < /dev/null &
    sleep 15 && ss -tlnp && curl -sI http://localhost:8080/api/ingredients" \
  --instance-id 1
