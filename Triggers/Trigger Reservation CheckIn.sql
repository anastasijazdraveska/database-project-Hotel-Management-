USE HotelManagement;
GO
CREATE TRIGGER trigger_Reservation_CheckIn
ON Reservation
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EmployeeID INT;

    SELECT TOP 1 @EmployeeID = i.EmployeeID
    FROM inserted i
    JOIN deleted d ON i.ReservationID = d.ReservationID
    WHERE i.ReservationStatus = 'Checked In'
      AND d.ReservationStatus = 'Confirmed';

    EXEC sp_set_session_context @key = N'CurrentEmployeeID', @value = @EmployeeID;

    UPDATE r
    SET r.RoomStatusID = rs.RoomStatusID
    FROM Room r
    JOIN inserted i ON r.RoomID = i.RoomID
    JOIN deleted d ON i.ReservationID = d.ReservationID
    JOIN RoomStatus rs ON rs.StatusName = 'Occupied'
    WHERE i.ReservationStatus = 'Checked In'
      AND d.ReservationStatus = 'Confirmed';
END;
GO
