
var handle Server.    // socketserver where philosophers connect to
var char[5] Info .    // number of philosophers
var logical AllowEat. // flag that the eating can start

define temp-table Philosopher no-undo
    field Id as integer
    field Socket as handle
    index kId as primary Id
    index kSocket Socket
    .
define temp-table Chopstick no-undo
    field Id as integer
    field InUse as logical
    index kId as primary Id
    .

// userinterface
define frame F
    Info format "x(40)"
with view-as dialog-box 1 column.

view frame F.
current-window:hidden = true.

// functions
function ShowInfo returns logical (Id as integer,Note as character):
    Info[Id] = Note.
    display Info with frame F.
end function.

function WriteData returns logical (Socket as handle,Note as character):
    var memptr Data.
    var int Bytes.
    Bytes = length(Note) + 1.
    set-size(Data) = Bytes.
    put-string(Data,1) = Note.
    Socket:write(Data,1,Bytes).
    finally:
        set-size(Data) = 0.
    end finally.
end function.

function ReadData returns character (Socket as handle):
    var memptr Data.
    var int Bytes.
    Bytes = Socket:get-bytes-available().
    set-size(Data) = Bytes.
    Socket:read(Data,1,Bytes).
    return get-string(Data,1).
    finally:
        set-size(Data) = 0.
    end finally.
end function.

function StartServer returns handle ( Port as integer ):
    var handle Server.
    create server-socket Server.
    Server:set-connect-procedure("Connect").
    Server:enable-connections(substitute("-S &1",Port)).
    frame F:title = substitute("listen to port: &1",Port) .
    return Server.
end function.

function CanEat returns logical (Id as integer):
    define buffer ChopstickLeft  for Chopstick.
    define buffer ChopstickRight for Chopstick.
    find ChopstickLeft  where ChopstickLeft.Id  = Id.
    find ChopstickRight where ChopstickRight.Id = (Id mod extent(Info) + 1).
    if  ChopstickLeft.InUse  eq false
    and ChopstickRight.InUse eq false
    then do:
        ChopstickLeft.InUse  = true.
        ChopstickRight.InUse = true.
        return true.
    end.
    return false.
end function.

function ReleaseChopsticks returns logical (Id as integer):
    define buffer ChopstickLeft for Chopstick.
    define buffer ChopstickRight for Chopstick.
    find ChopstickLeft  where ChopstickLeft.Id  = Id.
    find ChopstickRight where ChopstickRight.Id = (Id mod extent(Info) + 1).
    ChopstickLeft.InUse  = false.
    ChopstickRight.InUse = false.
    return true.
end function.


// initialize
Server = StartServer (13002).

// main
wait-for go,end-error of frame F.

// cleanup and finish
delete object Server no-error.
quit.


// philosopher connection
procedure Connect:
    define input parameter Socket  as handle      no-undo.
    define buffer Philosopher for Philosopher.
    define buffer Chopstick for Chopstick.
    var int Id = 1.

    for last Philosopher:
        Id = Philosopher.Id + 1.
    end.

    ShowInfo(Id , substitute("connection: &1",Id)).

    Socket:set-read-response-procedure("Response").

    create Philosopher.
    assign Philosopher.Id = Id
           Philosopher.Socket = Socket
           .
    create Chopstick.
    assign Chopstick.Id = Id
           Chopstick.InUse = false
           .
    // give philosopher its name/number
    WriteData(Socket,substitute("Philosopher: &1",Id)).

    // determine flag to indicate that eating can start
    AllowEat = Id eq extent(Info).

end procedure.

procedure Response:
    define buffer Philosopher for Philosopher.
    var char Response, Note.

    find Philosopher where Philosopher.Socket eq self.

    // philosopher has disconnected (done eating)
    if not self:connected()
    then do:
        ShowInfo(Philosopher.Id,substitute("disconnected: &1",Philosopher.Id)).
        delete Philosopher.
        delete object self.
        return.
    end.

    Response = ReadData(self).
    ShowInfo(Philosopher.Id,Response).

    if AllowEat then
    case Response:
        when "request to eat"
        then do:
            if CanEat(Philosopher.Id)
            then WriteData(Philosopher.Socket,"allowed to eat").
            else ShowInfo(Philosopher.Id,"rejected request to eat").
        end.
        when "meal finished"
        then do:
            ReleaseChopsticks(Philosopher.Id).
        end.
    end case.
end procedure.

