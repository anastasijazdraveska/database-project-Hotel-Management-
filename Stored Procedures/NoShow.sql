USE HotelManagement;
GO

CREATE OR ALTER PROCEDURE dbo.NoShow
(
    @ReservationID INT,
    @NoShowDate DATETIME2 = NULL
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

            @NoShowPercent DECIMAL(5,2) = 100,
            @NoShowFee DECIMAL(10,2),

            @BillID INT,

            @RoomID INT,
            @AvailableStatusID INT;


        -------------------------------------------------
        -- No Show date
        -------------------------------------------------

        IF @NoShowDate IS NULL
            SET @NoShowDate = SYSDATETIME();


        -------------------------------------------------
        -- Get reservation
        -------------------------------------------------

        SELECT
            @ReservationStatus = ReservationStatus,
            @RatePlanID = RatePlanID,
            @CheckIn = CheckIn,
            @CheckOut = CheckOut,
            @RoomID = RoomID
        FROM Reservation
        WHERE ReservationID = @ReservationID;


        -------------------------------------------------
        -- Reservation exists
        -------------------------------------------------

        IF @ReservationStatus IS NULL
        BEGIN
            RAISERROR(
                'Reservation does not exist.',
                16,
                1
            );

            ROLLBACK TRANSACTION;
            RETURN;
        END;


        -------------------------------------------------
        -- Only Confirmed reservations
        -------------------------------------------------

        IF @ReservationStatus <> 'Confirmed'
        BEGIN
            RAISERROR(
                'Only confirmed reservations can be marked as No Show.',
                16,
                1
            );

            ROLLBACK TRANSACTION;
            RETURN;
        END;


        -------------------------------------------------
        -- No Show cannot happen before Check-In
        -------------------------------------------------

        IF @NoShowDate < @CheckIn
        BEGIN
            RAISERROR(
                'No Show date cannot be before the reservation check-in date.',
                16,
                1
            );

            ROLLBACK TRANSACTION;
            RETURN;
        END;


        -------------------------------------------------
        -- Reserved nights
        -------------------------------------------------

        SET @ReservedNights =
            DATEDIFF(
                DAY,
                @CheckIn,
                @CheckOut
            );

        IF @ReservedNights <= 0
            SET @ReservedNights = 1;


        -------------------------------------------------
        -- Price per night
        -------------------------------------------------

        SELECT
            @PricePerNight = PricePerNight
        FROM RatePlan
        WHERE RatePlanID = @RatePlanID;


        IF @PricePerNight IS NULL
        BEGIN
            RAISERROR(
                'Rate plan does not exist.',
                16,
                1
            );

            ROLLBACK TRANSACTION;
            RETURN;
        END;


        -------------------------------------------------
        -- Accommodation amount
        -------------------------------------------------

        SET @AccommodationAmount =
            @ReservedNights * @PricePerNight;


        -------------------------------------------------
        -- No Show fee = 100%
        -------------------------------------------------

        SET @NoShowFee =
            @AccommodationAmount *
            (@NoShowPercent / 100.0);


        -------------------------------------------------
        -- Find existing Bill
        -------------------------------------------------

        SELECT
            @BillID = BillID
        FROM Bill
        WHERE ReservationID = @ReservationID;


        -------------------------------------------------
        -- Create Bill if necessary
        -------------------------------------------------

        IF @BillID IS NULL
        BEGIN

            INSERT INTO Bill
            (
                ReservationID,
                BillDate,
                BillStatus,
                TotalAmount
            )
            VALUES
            (
                @ReservationID,
                @NoShowDate,
                'Unpaid',
                0
            );

            SET @BillID = SCOPE_IDENTITY();

        END;


        -------------------------------------------------
        -- Insert No Show charge
        -------------------------------------------------

        INSERT INTO ReservationCharge
        (
            BillID,
            ChargeType,
            Amount
        )
        VALUES
        (
            @BillID,
            'No Show Fee',
            @NoShowFee
        );


        -------------------------------------------------
        -- Find Available room status
        -------------------------------------------------

        SELECT
            @AvailableStatusID = RoomStatusID
        FROM RoomStatus
        WHERE StatusName = 'Available';


        IF @AvailableStatusID IS NULL
        BEGIN
            RAISERROR(
                'Available room status does not exist.',
                16,
                1
            );

            ROLLBACK TRANSACTION;
            RETURN;
        END;


        -------------------------------------------------
        -- Update reservation
        -------------------------------------------------

        UPDATE Reservation
        SET
            ReservationStatus = 'No Show'
        WHERE ReservationID = @ReservationID;


        -------------------------------------------------
        -- Release room
        -------------------------------------------------

        UPDATE Room
        SET
            RoomStatusID = @AvailableStatusID
        WHERE RoomID = @RoomID;


        COMMIT TRANSACTION;

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH

END;
GO