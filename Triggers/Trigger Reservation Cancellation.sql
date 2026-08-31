USE HotelManagement1;
GO

CREATE TRIGGER trigger_Reservation_Cancellation
ON Reservation
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE r
    SET r.CancellationDate = CAST(GETDATE() AS DATE)
    FROM Reservation r

    JOIN inserted i
        ON r.ReservationID = i.ReservationID

    JOIN deleted d
        ON i.ReservationID = d.ReservationID

    WHERE i.ReservationStatus = 'Cancelled'
      AND d.ReservationStatus = 'Confirmed';

END;
GO