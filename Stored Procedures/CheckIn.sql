USE [HotelManagement]
GO
/****** Object:  StoredProcedure [dbo].[CheckInGuest]    Script Date: 02/09/2026 12:35:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[CheckInGuest]
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
            @ScheduledCheckIn DATETIME2;

        -- If no actual check-in date is supplied,
        -- use the current date/time
        IF @ActualCheckIn IS NULL
            SET @ActualCheckIn = SYSDATETIME();

        -- Get reservation information
        SELECT
            @ReservationStatus = ReservationStatus,
            @RoomID = RoomID,
            @ScheduledCheckIn = CheckIn
        FROM dbo.Reservation
        WHERE ReservationID = @ReservationID;

        -- Reservation exists?
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
        IF @ActualCheckIn < @ScheduledCheckIn
        BEGIN
            RAISERROR(
                'Actual check-in cannot be before the scheduled check-in date.',
                16,
                1
            );

            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Update Reservation
        UPDATE dbo.Reservation
        SET
            ActualCheckIn = @ActualCheckIn,
            ReservationStatus = 'Checked In'
        WHERE ReservationID = @ReservationID;

        COMMIT TRANSACTION;

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH
END;
