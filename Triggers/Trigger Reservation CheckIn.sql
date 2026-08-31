USE HotelManagement1;
GO

CREATE TRIGGER trigger_Reservation_CheckIn
ON Reservation
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE r
    SET r.RoomStatusID = rs.RoomStatusID
    FROM Room r
    JOIN inserted i
        ON r.RoomID = i.RoomID
    JOIN deleted d
        ON i.ReservationID = d.ReservationID
    JOIN RoomStatus rs
        ON rs.StatusName = 'Occupied'
    WHERE i.ReservationStatus = 'Checked In'
      AND d.ReservationStatus = 'Confirmed';

    INSERT INTO RoomStatusHistory
    (
        RoomID,
        EmployeeID,
        RoomStatusID,
        ChangeDateTime
    )
    SELECT
        i.RoomID,
        i.EmployeeID,
        rs.RoomStatusID,
        GETDATE()
    FROM inserted i
    JOIN deleted d
        ON i.ReservationID = d.ReservationID
    JOIN RoomStatus rs
        ON rs.StatusName = 'Occupied'
    WHERE i.ReservationStatus = 'Checked In'
      AND d.ReservationStatus = 'Confirmed';

END;
GO