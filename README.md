# PBExpress
Lightweight PureBasic FastCGI Framework

**STATUS:** ALPHA | **FEATURE-FERTIG:** NEIN


## Was ist es?
Es ist/wird ein in PureBasic geschriebenes Framework für das entwickeln hochperformanter Webanwendungen. PureBasic besitzt mittlerweile eine FastCGI-Implementierung, die im Grunde bereits die schwerste aller Aufgaben übernimmt. Allerdings reicht diese Implementierung nicht aus. Es fehlen noch Unmengen an Funktionalitäten, um damit entspannt Webanwendungen zu entwickeln. Aus diesem Grund wird PBExpress entwickelt.

## Warum dieser Name?
Das Routing innerhalb von PBExpress ist ein wenig von Express.js inspiriert, welches für Node.js entwickelt wurde. Da war es naheliegend, einen ähnlichen Namen zu verwenden. Nur hier wurde eben kein .pb dahinter, sondern das PB davor gesetzt.

## Irgendwelche Besonderheiten?
PBExpress nutzt FastCGI, um sich leicht an jeden beliebigen Webserver anbinden zu lassen. Im Gegensatz zu Node ist FastCGI ein Blocked-IO. Es wird erst der nächste Request abgearbeitet, wenn der vorige fertig ist. Das hat den Vorteil, das die Informationen und Daten Konsistent bleiben. Allerdings leidet ein wenig die Skallierbarkeit. Ebenfalls ist es mit der Skallierung schwierig, da die FastCGI die Requests nicht wirklich kennzeichnet. Man bekommt keine ID oder ein Handle für den Request, weswegen für mehrere Threads auch mehrere Listener benötigt werden. Mit FastCGI also parallelisiert zu arbeiten, ist ein Loadbalancer unausweichlich. Aber das gute ist: "Es funktioniert perfekt"

Wenn die Anwendung Singlethreaded implementiert wird und den TCP-Port beim Start als Parameter erwartet, dann kann man mit einem Bash-/Batch-Script viele Instanzen laufen lassen und somit seine Serverhardware ideal ausnutzen, während der Loadbalancer des Webservers sich darum kümmert, die Anfragen homogen zu verteilen.

Ebenfalls wichtig zu wissen ist, das die Module so geschrieben sind, das sie völlig unabhängig voneinander laufen. Sollte also irgendwer eine andere Funktionalität für Sessions verwenden wollen, kann er das FileSession-Modul einfach weglassen. Hat jemand einen Webserver für PureBasic geschrieben und möchte dafür Security und FileSession verwenden, so kann er das ohne Einschränkungen tun.

## Dokumentation?
Zur Zeit wird das Projekt nur in deutscher Sprache gepflegt. Daher ist auch das Wiki in deutscher Sprache. Das Wiki befindet sich oben in den Reitern. Oder man klickt auf diesen Link: [Zum Wiki](https://github.com/reVerBxTc/PBExpress/wiki)

News gibt es unter: [Zu den News](NEWS.md)
