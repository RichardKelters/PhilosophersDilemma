@echo off
set DLC=C:\Progress\OpenEdge123

REM Number of Philosophers
set num=5

start %DLC%\bin\prowin -p waiter.p -param %num%

for /l %%x in (1, 1, %num%) do (
    start %DLC%\bin\prowin -p philosopher.p
)

