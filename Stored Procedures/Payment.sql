USE [HotelManagement]
GO
/****** Object:  StoredProcedure [dbo].[RegisterPayment]    Script Date: 02/09/2026 12:59:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER   PROCEDURE [dbo].[RegisterPayment]
(
    @BillID INT,
    @Amount DECIMAL(10,2),
    @PaymentMethodID INT,
    @PaymentDate DATETIME2 = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        BEGIN TRANSACTION;

        DECLARE
            @BillStatus NVARCHAR(30),
            @TotalAmount DECIMAL(10,2),
            @AlreadyPaid DECIMAL(10,2),
            @RemainingAmount DECIMAL(10,2);

        -- If no payment date is supplied,
        -- use the current date/time
        IF @PaymentDate IS NULL
            SET @PaymentDate = SYSDATETIME();

        -- Get bill information
        SELECT
            @BillStatus = BillStatus,
            @TotalAmount = TotalAmount
        FROM dbo.Bill WITH (UPDLOCK, HOLDLOCK)
        WHERE BillID = @BillID;

        -- Bill must exist
        IF @TotalAmount IS NULL
        BEGIN
            RAISERROR(
                'Bill does not exist.',
                16,
                1
            );

            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Cancelled bills cannot receive payments
        IF @BillStatus = 'Cancelled'
        BEGIN
            RAISERROR(
                'Cannot register a payment for a cancelled bill.',
                16,
                1
            );

            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Already paid bills cannot receive additional payments
        IF @BillStatus = 'Paid'
        BEGIN
            RAISERROR(
                'Bill is already fully paid.',
                16,
                1
            );

            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Payment amount must be positive
        IF @Amount <= 0
        BEGIN
            RAISERROR(
                'Payment amount must be greater than zero.',
                16,
                1
            );

            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Payment method must exist
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.PaymentMethod
            WHERE PaymentMethodID = @PaymentMethodID
        )
        BEGIN
            RAISERROR(
                'Payment method does not exist.',
                16,
                1
            );

            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Calculate amount already paid
        SELECT
            @AlreadyPaid = ISNULL(SUM(Amount), 0)
        FROM dbo.Payment
        WHERE BillID = @BillID;

        -- Calculate remaining balance
        SET @RemainingAmount = @TotalAmount - @AlreadyPaid;

        -- Do not allow overpayment
        IF @Amount > @RemainingAmount
        BEGIN
            RAISERROR(
                'Payment amount exceeds the remaining balance of the bill.',
                16,
                1
            );

            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Register payment
        INSERT INTO dbo.Payment
        (
            BillID,
            Amount,
            PaymentMethodID,
            PaymentDate
        )
        VALUES
        (
            @BillID,
            @Amount,
            @PaymentMethodID,
            @PaymentDate
        );

        -- Mark bill as Paid if the remaining balance was fully paid
        IF @Amount = @RemainingAmount
        BEGIN
            UPDATE dbo.Bill
            SET BillStatus = 'Paid'
            WHERE BillID = @BillID;
        END;

        COMMIT TRANSACTION;

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH
END;
