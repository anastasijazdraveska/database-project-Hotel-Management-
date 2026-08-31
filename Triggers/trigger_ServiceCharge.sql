CREATE OR ALTER TRIGGER trigger_ServiceCharge
ON ServiceCharge
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Bills TABLE
    (
        BillID INT PRIMARY KEY
    );

    INSERT INTO @Bills(BillID)
    SELECT DISTINCT BillID
    FROM inserted
    WHERE BillID IS NOT NULL

    UNION

    SELECT DISTINCT BillID
    FROM deleted
    WHERE BillID IS NOT NULL;

    UPDATE B
    SET TotalAmount =
        ISNULL(RC.TotalReservationCharges,0)
        +
        ISNULL(SC.TotalServiceCharges,0)
    FROM Bill B
    INNER JOIN @Bills X
        ON B.BillID = X.BillID

    OUTER APPLY
    (
        SELECT SUM(Amount) AS TotalReservationCharges
        FROM ReservationCharge
        WHERE BillID = B.BillID
    ) RC

    OUTER APPLY
    (
        SELECT SUM(Amount) AS TotalServiceCharges
        FROM ServiceCharge
        WHERE BillID = B.BillID
    ) SC;

END;
GO