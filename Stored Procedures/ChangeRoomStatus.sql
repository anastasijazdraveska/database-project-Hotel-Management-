CREATE OR ALTER PROCEDURE ChangeRoomStatus
(
    @RoomID INT,
    @NewRoomStatusID INT
)
AS
BEGIN

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        BEGIN TRANSACTION;

        DECLARE
            @CurrentStatusID INT,
            @CurrentStatusName NVARCHAR(50),
            @NewStatusName NVARCHAR(50);



        SELECT
            @CurrentStatusID = RoomStatusID
        FROM Room
        WHERE RoomID = @RoomID;

        IF @CurrentStatusID IS NULL
        BEGIN
            RAISERROR('Room does not exist.',16,1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;


        SELECT
            @NewStatusName = StatusName
        FROM RoomStatus
        WHERE RoomStatusID = @NewRoomStatusID;

        IF @NewStatusName IS NULL
        BEGIN
            RAISERROR('Invalid room status.',16,1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Current status name

        SELECT
            @CurrentStatusName = StatusName
        FROM RoomStatus
        WHERE RoomStatusID = @CurrentStatusID;


        -- Cannot manually set occupied or cleaning

        -- occupied preku ChecIn
        -- cleaning preku CheckOut
        IF @NewStatusName IN ('Occupied','Cleaning')
        BEGIN
            RAISERROR('Occupied and Cleaning statuses can only be set automatically by Check-In and Check-Out procedures.',16,1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        
        -- Available
        IF @CurrentStatusName = 'Available'
        BEGIN

            IF @NewStatusName NOT IN
            (
                'Under Maintenance',
                'Out of Service'
            )
            BEGIN
                RAISERROR('Available rooms can only be changed to Under Maintenance or Out of Service.',16,1);
                ROLLBACK TRANSACTION;
                RETURN;
            END;

        END

        -- Occupied
        ELSE IF @CurrentStatusName = 'Occupied'
        BEGIN

            IF @NewStatusName NOT IN
            (
                'Under Maintenance',
                'Out of Service'
            )
            BEGIN
                RAISERROR('Occupied rooms can only be changed to Under Maintenance or Out of Service manually.',16,1);
                ROLLBACK TRANSACTION;
                RETURN;
            END;

        END

        -- Cleaning

        ELSE IF @CurrentStatusName = 'Cleaning'
        BEGIN

            IF @NewStatusName NOT IN
            (
                'Available',
                'Under Maintenance',
                'Out of Service'
            )
            BEGIN
                RAISERROR('Cleaning rooms can only become Available, Under Maintenance or Out of Service.',16,1);
                ROLLBACK TRANSACTION;
                RETURN;
            END;

        END

        -- Under Maintenance
        ELSE IF @CurrentStatusName = 'Under Maintenance'
        BEGIN

            IF @NewStatusName <> 'Available'
            BEGIN
                RAISERROR('Rooms under maintenance can only become Available.',16,1);
                ROLLBACK TRANSACTION;
                RETURN;
            END;

        END

        
        -- Out of Service
        

        ELSE IF @CurrentStatusName = 'Out of Service'
        BEGIN

            IF @NewStatusName <> 'Available'
            BEGIN
                RAISERROR('Out of Service rooms can only become Available.',16,1);
                ROLLBACK TRANSACTION;
                RETURN;
            END;

        END;

        UPDATE Room
        SET RoomStatusID = @NewRoomStatusID
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
