USE HotelManagement;
GO

CREATE OR ALTER TRIGGER trigger_UpdateBillFromReservationCharge
ON ReservationCharge
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE b
    SET b.TotalAmount =
        ISNULL(
            (
                SELECT SUM(rc.Amount)
                FROM ReservationCharge rc
                WHERE rc.BillID = b.BillID
            ), 0
        )
        +
        ISNULL(
            (
                SELECT SUM(sc.Amount)
                FROM ServiceCharge sc
                WHERE sc.BillID = b.BillID
            ), 0
        )
    FROM Bill b
    WHERE b.BillID IN
    (
        SELECT BillID FROM inserted
        UNION
        SELECT BillID FROM deleted
    );
END;
GO