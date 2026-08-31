CREATE OR ALTER PROCEDURE CheckInGuest
(
    @ReservationID INT,
    @ActualCheckIn DATETIME2 = NULL
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
            @OccupiedStatusID INT;


        -- If no actual check-in date is supplied,
        -- use the current date/time
        IF @ActualCheckIn IS NULL
            SET @ActualCheckIn = SYSDATETIME();


        -- Reservation exists?
        SELECT
            @ReservationStatus = ReservationStatus,
            @RoomID = RoomID
        FROM Reservation
        WHERE ReservationID = @ReservationID;


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


        -- Reservation must be confirmed
        IF @ReservationStatus <> 'Confirmed'
        BEGIN
            RAISERROR(
                'Only confirmed reservations can be checked in.',
                16,
                1
            );

            ROLLBACK TRANSACTION;
            RETURN;
        END;


        -- Actual check-in cannot be before scheduled check-in
        IF @ActualCheckIn < (
            SELECT CheckIn
            FROM Reservation
            WHERE ReservationID = @ReservationID
        )
        BEGIN
            RAISERROR(
                'Actual check-in cannot be before the scheduled check-in date.',
                16,
                1
            );

            ROLLBACK TRANSACTION;
            RETURN;
        END;


        -- Get Occupied status
        SELECT
            @OccupiedStatusID = RoomStatusID
        FROM RoomStatus
        WHERE StatusName = 'Occupied';


        IF @OccupiedStatusID IS NULL
        BEGIN
            RAISERROR(
                'Room status Occupied does not exist.',
                16,
                1
            );

            ROLLBACK TRANSACTION;
            RETURN;
        END;


        -- Update Reservation
        UPDATE Reservation
        SET
            ActualCheckIn = @ActualCheckIn,
            ReservationStatus = 'Checked In'
        WHERE ReservationID = @ReservationID;


        -- Update Room
        UPDATE Room
        SET
            RoomStatusID = @OccupiedStatusID
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