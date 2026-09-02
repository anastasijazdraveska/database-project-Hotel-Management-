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
            @EmployeeID INT,
            @AvailableStatusID INT;

        IF @NoShowDate IS NULL
            SET @NoShowDate = SYSDATETIME();

        SELECT
            @ReservationStatus = ReservationStatus,
            @RatePlanID = RatePlanID,
            @CheckIn = CheckIn,
            @CheckOut = CheckOut,
            @RoomID = RoomID,
            @EmployeeID = EmployeeID
        FROM Reservation
        WHERE ReservationID = @ReservationID;

        IF @ReservationStatus IS NULL
        BEGIN
            RAISERROR('Reservation does not exist.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        IF @ReservationStatus <> 'Confirmed'
        BEGIN
            RAISERROR('Only confirmed reservations can be marked as No Show.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        IF @NoShowDate < @CheckIn
        BEGIN
            RAISERROR('No Show date cannot be before the reservation check-in date.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        SET @ReservedNights = DATEDIFF(DAY, @CheckIn, @CheckOut);
        IF @ReservedNights <= 0
            SET @ReservedNights = 1;

        SELECT @PricePerNight = PricePerNight FROM RatePlan WHERE RatePlanID = @RatePlanID;
        IF @PricePerNight IS NULL
        BEGIN
            RAISERROR('Rate plan does not exist.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        SET @AccommodationAmount = @ReservedNights * @PricePerNight;
        SET @NoShowFee = @AccommodationAmount * (@NoShowPercent / 100.0);

        SELECT @BillID = BillID FROM Bill WHERE ReservationID = @ReservationID;

        IF @BillID IS NULL
        BEGIN
            INSERT INTO Bill (ReservationID, BillDate, BillStatus, TotalAmount)
            VALUES (@ReservationID, @NoShowDate, 'Unpaid', 0);
            SET @BillID = SCOPE_IDENTITY();
        END;

        INSERT INTO ReservationCharge (BillID, ChargeType, Amount)
        VALUES (@BillID, 'No Show Fee', @NoShowFee);

        SELECT @AvailableStatusID = RoomStatusID FROM RoomStatus WHERE StatusName = 'Available';
        IF @AvailableStatusID IS NULL
        BEGIN
            RAISERROR('Available room status does not exist.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        UPDATE Reservation
        SET ReservationStatus = 'No Show'
        WHERE ReservationID = @ReservationID;

        -- Attribute this room status change to the employee
        -- who processed the No Show (read by trigger_Room_StatusHistory)

        EXEC sp_set_session_context @key = N'CurrentEmployeeID', @value = @EmployeeID;

        UPDATE Room
        SET RoomStatusID = @AvailableStatusID
        WHERE RoomID = @RoomID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
