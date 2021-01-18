
var handle Server.
var char[5] Info .
var logical AllowEat.

define frame F
    Info format "x(40)"
with view-as dialog-box 1 column.

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

view frame F.
current-window:hidden = true.
run StartServer (13000,output Server).

wait-for go of frame F.
delete object Server no-error.


procedure StartServer:
    define input  paramete  Port as integer      no-undo.
    define output parameter Server as handle      no-undo.
    create server-socket Server.
    Server:set-connect-procedure("connect").
    Server:enable-connections(substitute("-S &1",Port)).
    Info = substitute("listen to port: &1",Port).
    display Info with frame F.
    return.
end procedure.

procedure connect:
    define input parameter Socket  as handle      no-undo.
    define buffer Philosopher for Philosopher.
    var int Id = 1.
    var int Bytes.
    var memptr Data.
    var char Note.

    for last Philosopher:
        Id = Philosopher.Id + 1.
    end.

    Info[Id] = substitute("connection: &1",Id).
    display Info[Id] with frame F.

    Socket:set-read-response-procedure("Response").

    create Philosopher.
    assign Philosopher.Id = Id
           Philosopher.Socket = Socket
           .
    create Chopstick.
    assign Chopstick.Id = Id
           Chopstick.InUse = false
           .
    Note = substitute("Philosopher: &1",Id).
    Bytes = length(Note) + 1.
    set-size(Data) = Bytes.
    put-string(Data,1) = Note.
    Socket:write(Data,1,Bytes).
    AllowEat = Id eq 5.
    finally:
        set-size(Data) = 0.
    end finally.
end procedure.

procedure Response:
    define buffer Philosopher for Philosopher.
    define buffer ChopstickLeft for Chopstick.
    define buffer ChopstickRight for Chopstick.
    var int Bytes.
    var memptr Data.
    var char Response, Note.

    find Philosopher where Philosopher.Socket eq self.
    if not self:connected()
    then do:
        Info[Philosopher.Id] = substitute("disconnected: &1",Philosopher.Id).
        display Info[Philosopher.Id] with frame F.
        delete Philosopher.
        delete object self.
        return.
    end.

    Bytes = self:get-bytes-available().
    set-size(Data) = Bytes.
    self:read(Data,1,Bytes).
    Response = get-string(Data,1).
    Info[Philosopher.Id] = Response.
    display Info with frame F.
    
    if AllowEat then
    case Response:
        when "request to eat" 
        then do:
            find ChopstickLeft where ChopstickLeft.Id = Philosopher.Id.
            if Philosopher.Id eq 1
            then find last ChopstickRight.
            else find ChopstickRight where ChopstickRight.Id = Philosopher.Id - 1.
            if  not ChopstickLeft.InUse
            and not ChopstickRight.InUse 
            then do:
                ChopstickLeft.InUse = true.
                ChopstickRight.InUse = true.
                Note = "allowed to eat".
                Bytes = length(Note) + 1.
                set-size(Data) = 0.
                set-size(Data) = Bytes.
                put-string(Data,1) = Note.
                Philosopher.Socket:write(Data,1,Bytes).
            end.
            else do:
                Info[Philosopher.Id] = "rejected request to eat".
                display Info[Philosopher.Id] with frame F.
            end.
        end.
        when "meal finished" 
        then do:
            find ChopstickLeft where ChopstickLeft.Id = Philosopher.Id.
            if Philosopher.Id eq 1
            then find last ChopstickRight.
            else find ChopstickRight where ChopstickRight.Id = Philosopher.Id - 1.
            ChopstickLeft.InUse = false.
            ChopstickRight.InUse = false.
        end.
    end case.
    finally:
        set-size(Data) = 0.
    end finally.
end procedure.

