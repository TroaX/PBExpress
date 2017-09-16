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

News gibt es unter: [Zu den News](https://github.com/reVerBxTc/PBExpress/blob/master/NEWS.md)

```basic
;
; ------------------------------------------------------------
;
;   PureBasic - 2D Drawing example file
;
;    (c) 2005 - Fantaisie Software
;
; ------------------------------------------------------------
;

If OpenWindow(0, 100, 200, 300, 200, "2D Drawing Test")

  ; Create an offscreen image, with a green circle in it.
  ; It will be displayed later
  ;
  If CreateImage(0, 300, 200)
    If StartDrawing(ImageOutput(0))
      Circle(100,100,50,RGB(0,0,255))  ; a nice blue circle...

      Box(150,20,20,20, RGB(0,255,0))  ; and a green box
      
      FrontColor(RGB(255,0,0)) ; Finally, red lines..
      For k=0 To 20
        LineXY(10,10+k*8,200, 0)
      Next
      
      DrawingMode(#PB_2DDrawing_Transparent)
      BackColor(RGB(0,155,155)) ; Change the text back and front colour
      FrontColor(RGB(255,255,255)) 
      DrawText(10,50,"Hello, this is a test")

      StopDrawing()
    EndIf
  EndIf

  ; Create a gadget to display our nice image
  ;  
  ImageGadget(0, 0, 0, 0, 0, ImageID(0))
  
  ;
  ; This is the 'event loop'. All the user actions are processed here.
  ; It's very easy to understand: when an action occurs, the Event
  ; isn't 0 and we just have to see what have happened...
  ;
  
  Repeat
    Event = WaitWindowEvent() 
  Until Event = #PB_Event_CloseWindow  ; If the user has pressed on the window close button
  
EndIf

End   ; All the opened windows are closed automatically by PureBasic
```

