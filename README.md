Устанавливаем:  
npm install -g --unsafe-perm homebridge-cmdswitch2  

Копируем *.sh файлы в домашнюю директорию /home/pi  
Устанавливаем всем chmod +x  

Пробуем авторизоваться: auth.sh 00:00:00:00:00:00  
вместо 00:00:00:00:00:00 указываете МАК своего устройства  

После пытаетесь включить, выключить или узнать текущее состояние запуская connect.sh  
connect.sh 00:00:00:00:00:00 on  
connect.sh 00:00:00:00:00:00 off  
connect.sh 00:00:00:00:00:00 status  

если всё ОК то прописываем в конфиг и не забываем поменять 00:00:00:00:00:00  

после тестирования удалите файл /tmp/response и перезапустите homebridge  

Добавляем в конфиг
```
"platforms": [
    {
        "platform": "cmdSwitch2",
        "name": "Switches",
        "switches": [
            {
                "name": "Свет",
                "on_cmd": "/home/pi/connect.sh 00:00:00:00:00:00 on",
                "off_cmd": "/home/pi/connect.sh 00:00:00:00:00:00 off",
                "state_cmd": "/home/pi/connect.sh 00:00:00:00:00:00 status | grep -l 'ON'",
                "manufacturer": "Redmond",
                "model": "RSP-202S"
            },
            {
                "name": "Обогреватель",
                "on_cmd": "/home/pi/connect.sh 00:00:00:00:00:00 on",
                "off_cmd": "/home/pi/connect.sh 00:00:00:00:00:00 off",
                "state_cmd": "/home/pi/connect.sh 00:00:00:00:00:00 status | grep -l 'ON'",
                "manufacturer": "Redmond",
                "model": "RSP-103S"
            }
        ]
    }
]
```