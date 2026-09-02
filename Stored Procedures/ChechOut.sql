CREATE OR ALTER PROCEDURE CheckOutGuest
(
    @ReservationID INT,
    @ActualCheckOut DATETIME2 = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE
            @ReservationStatus NVARCHAR(30),
            @RoomID INT,
            @RatePlanID INT,
            @BookingID INT,
            @EmployeeID INT,
            @CheckIn DATETIME2,
            @ActualCheckIn DATETIME2,
            @PricePerNight DECIMAL(10,2),
            @Discount DECIMAL(5,2),
            @NumberOfNights INT,
            @AccommodationAmount DECIMAL(10,2),
            @BillID INT,
            @CleaningStatusID INT;

        -- Get reservation information
        SELECT
            @ReservationStatus = ReservationStatus,
            @RoomID = RoomID,
            @RatePlanID = RatePlanID,
            @BookingID = BookingID,
            @EmployeeID = EmployeeID,
            @CheckIn = CheckIn,
            @ActualCheckIn = ActualCheckIn
        FROM Reservation
        WHERE ReservationID = @ReservationID;

        -- Reservation exists?
        IF @ReservationStatus IS NULL
        BEGIN
            RAISERROR('Reservation does not exist.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Reservation must be Checked In
        IF @ReservationStatus <> 'Checked In'
        BEGIN
            RAISERROR('Only checked in reservations can be checked out.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Actual Check-In must exist
        IF @ActualCheckIn IS NULL
        BEGIN
            RAISERROR('Actual check-in date does not exist.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- If no checkout date is supplied, use current date/time
        IF @ActualCheckOut IS NULL
        BEGIN
            SET @ActualCheckOut = SYSDATETIME();
        END;

        -- Actual checkout cannot be before actual check-in
        IF @ActualCheckOut < @ActualCheckIn
        BEGIN
            RAISERROR('Actual check-out date cannot be before actual check-in.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Actual checkout cannot be before scheduled check-in
        IF @ActualCheckOut < @CheckIn
        BEGIN
            RAISERROR('Actual check-out date cannot be before the scheduled check-in date.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;
        

        -- Number of nights
        
        SET @NumberOfNights = DATEDIFF(DAY, @ActualCheckIn, @ActualCheckOut);

        IF @NumberOfNights < 0
        BEGIN
            RAISERROR('Invalid number of nights.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Same-day stay = minimum 1 night
        IF @NumberOfNights = 0
        BEGIN
            SET @NumberOfNights = 1;
        END;
        
        -- Price per night
        SELECT @PricePerNight = PricePerNight FROM RatePlan WHERE RatePlanID = @RatePlanID;

        IF @PricePerNight IS NULL
        BEGIN
            RAISERROR('Rate plan does not exist.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;
        
        -- Discount
        SELECT @Discount = DiscountPercentage FROM Booking WHERE BookingID = @BookingID;

        IF @Discount IS NULL
        BEGIN
            SET @Discount = 0;
        END;

        -- Accommodation amount
        SET @AccommodationAmount = (@NumberOfNights * @PricePerNight) * (1 - (@Discount / 100.0));


        -- Update reservation
        
        UPDATE Reservation
        SET
            ActualCheckOut = @ActualCheckOut,
            ReservationStatus = 'Completed'
        WHERE ReservationID = @ReservationID;
        


        -- Room -> Cleaning
        SELECT @CleaningStatusID = RoomStatusID FROM RoomStatus WHERE StatusName = 'Cleaning';

        IF @CleaningStatusID IS NULL
        BEGIN
            RAISERROR('Room status Cleaning does not exist.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Attribute this room status change to the employee
        -- who processed the check-out (read by trigger_Room_StatusHistory)
        EXEC sp_set_session_context @key = N'CurrentEmployeeID', @value = @EmployeeID;

        UPDATE Room
        SET RoomStatusID = @CleaningStatusID
        WHERE RoomID = @RoomID;


        -- Find existing Bill
        
        SELECT @BillID = BillID FROM Bill WHERE ReservationID = @ReservationID;

        -- Create Bill if necessary
        IF @BillID IS NULL
        BEGIN
            INSERT INTO Bill (ReservationID, BillDate, BillStatus, TotalAmount)
            VALUES (@ReservationID, @ActualCheckOut, 'Unpaid', 0);

            SET @BillID = SCOPE_IDENTITY();
        END;
        -- Prevent duplicate accommodation charge
        IF NOT EXISTS
        (
            SELECT 1 FROM ReservationCharge
            WHERE BillID = @BillID AND ChargeType = 'Accommodation'
        )
        BEGIN
            INSERT INTO ReservationCharge (BillID, ChargeType, Amount)
            VALUES (@BillID, 'Accommodation', @AccommodationAmount);
        END;

        -- Commit
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
