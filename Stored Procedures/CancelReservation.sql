USE [HotelManagement]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[CancelReservation]
(
    @ReservationID INT,
    @CancellationDate DATETIME2 = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        BEGIN TRANSACTION;

        DECLARE
            @ReservationStatus NVARCHAR(30),
            @RatePlanID INT,
            @CheckIn DATETIME2,
            @CheckOut DATETIME2,
            @PricePerNight DECIMAL(10,2),
            @ReservedNights INT,
            @AccommodationAmount DECIMAL(10,2),
            @DaysBeforeCheckIn INT,
            @CancellationPercent DECIMAL(5,2),
            @CancellationFee DECIMAL(10,2),
            @BillID INT;

        -- Cancellation date (се користи само за пресметка на таксата)
        IF @CancellationDate IS NULL
            SET @CancellationDate = SYSDATETIME();

        -- Get reservation
        SELECT
            @ReservationStatus = ReservationStatus,
            @RatePlanID = RatePlanID,
            @CheckIn = CheckIn,
            @CheckOut = CheckOut
        FROM Reservation
        WHERE ReservationID = @ReservationID;

        -- Reservation exists
        IF @ReservationStatus IS NULL
        BEGIN
            RAISERROR('Reservation does not exist.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Only Confirmed reservations
        IF @ReservationStatus <> 'Confirmed'
        BEGIN
            RAISERROR('Only confirmed reservations can be cancelled.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Cancellation must be before Check-In
        IF @CancellationDate >= @CheckIn
        BEGIN
            RAISERROR('Cancellation date must be before the reservation check-in date.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Reserved nights
        SET @ReservedNights = DATEDIFF(DAY, @CheckIn, @CheckOut);

        IF @ReservedNights <= 0
            SET @ReservedNights = 1;

        -- Price per night
        SELECT
            @PricePerNight = PricePerNight
        FROM RatePlan
        WHERE RatePlanID = @RatePlanID;

        IF @PricePerNight IS NULL
        BEGIN
            RAISERROR('Rate plan does not exist.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Accommodation amount
        SET @AccommodationAmount = @ReservedNights * @PricePerNight;

        -- Days before Check-In
        SET @DaysBeforeCheckIn = DATEDIFF(DAY, @CancellationDate, @CheckIn);

        -- Cancellation policy
        IF @DaysBeforeCheckIn > 7
            SET @CancellationPercent = 0;
        ELSE IF @DaysBeforeCheckIn BETWEEN 2 AND 7
            SET @CancellationPercent = 30;
        ELSE
            SET @CancellationPercent = 50;

        -- Cancellation fee
        SET @CancellationFee = @AccommodationAmount * (@CancellationPercent / 100.0);

        -- Find existing Bill
        SELECT
            @BillID = BillID
        FROM Bill
        WHERE ReservationID = @ReservationID;

        -- Create Bill only when there is a fee
        IF @CancellationFee > 0
        BEGIN
            IF @BillID IS NULL
            BEGIN
                INSERT INTO Bill (ReservationID, BillDate, BillStatus, TotalAmount)
                VALUES (@ReservationID, @CancellationDate, 'Unpaid', 0);

                SET @BillID = SCOPE_IDENTITY();
            END;

            -- Cancellation charge
            INSERT INTO ReservationCharge (BillID, ChargeType, Amount)
            VALUES (@BillID, 'Cancellation Fee', @CancellationFee);
        END;

        -- Update reservation status — CancellationDate ја пополнува trigger_Reservation_Cancellation автоматски
        UPDATE Reservation
        SET ReservationStatus = 'Cancelled'
        WHERE ReservationID = @ReservationID;

        COMMIT TRANSACTION;

    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH

END;
