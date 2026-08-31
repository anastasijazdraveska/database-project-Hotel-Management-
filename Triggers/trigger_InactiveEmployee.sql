CREATE OR ALTER TRIGGER InactiveEmployeeShift
ON EmployeeShift
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM inserted i
        INNER JOIN Employee e
            ON i.EmployeeID = e.EmployeeID
        WHERE e.Status = 'Inactive'
    )
    BEGIN
        RAISERROR(
            'Inactive employees cannot be assigned to a shift.',
            16,
            1
        );

        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO