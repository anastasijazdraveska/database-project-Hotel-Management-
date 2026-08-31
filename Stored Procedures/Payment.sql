CREATE OR ALTER PROCEDURE RegisterPayment
(
    @BillID INT,
    @PaymentMethodID INT
)
AS
BEGIN

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        BEGIN TRANSACTION;

        DECLARE
            @TotalAmount DECIMAL(10,2),
            @BillStatus NVARCHAR(30);


        SELECT
            @TotalAmount = TotalAmount,
            @BillStatus = BillStatus
        FROM Bill
        WHERE BillID = @BillID;

        IF @TotalAmount IS NULL
        BEGIN
            RAISERROR('Bill does not exist.',16,1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Bill already paid
        

        IF @BillStatus = 'Paid'
        BEGIN
            RAISERROR('This bill has already been paid.',16,1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Payment method exists-

        IF NOT EXISTS
        (
            SELECT 1
            FROM PaymentMethod
            WHERE PaymentMethodID = @PaymentMethodID
        )
        BEGIN
            RAISERROR('Invalid payment method.',16,1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Insert payment

        INSERT INTO Payment
        (
            BillID,
            PaymentMethodID,
            Amount,
            PaymentDate
        )
        VALUES
        (
            @BillID,
            @PaymentMethodID,
            @TotalAmount,
            SYSDATETIME()
        );

        -- Update bill

        UPDATE Bill
        SET BillStatus = 'Paid'
        WHERE BillID = @BillID;

        COMMIT TRANSACTION;

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH

END;
GO



EXEC RegisterPayment
    @BillID = 1,
    @PaymentMethodID = 2;