/* ============================================================
   HOTEL MANAGEMENT SYSTEM
   DATABASE STRUCTURE
   ============================================================ */

USE HotelManagement;
GO




/* ============================================================
   1. ROOM CATEGORY
   Catalog of room categories
   ============================================================ */

CREATE TABLE RoomCategory
(
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,

    CategoryName NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(200) NULL,

    MaximumGuests INT NOT NULL,
    RoomSize DECIMAL(6,2) NOT NULL,

    BedType NVARCHAR(50) NOT NULL,
    NumberOfBeds INT NOT NULL,

    HasBalcony BIT NOT NULL,

    CONSTRAINT CK_RoomCategory_MaximumGuests
        CHECK (MaximumGuests > 0),

    CONSTRAINT CK_RoomCategory_RoomSize
        CHECK (RoomSize > 0),

    CONSTRAINT CK_RoomCategory_NumberOfBeds
        CHECK (NumberOfBeds > 0)
);
GO


/* ============================================================
   2. SEASON
   Defines pricing seasons
   ============================================================ */

CREATE TABLE Season
(
    SeasonID INT IDENTITY(1,1) PRIMARY KEY,

    SeasonName NVARCHAR(50) NOT NULL UNIQUE,

    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,

    CONSTRAINT CK_Season_Dates
        CHECK (EndDate >= StartDate)
);
GO


/* ============================================================
   3. MEAL PLAN
   Catalog of meal plans
   ============================================================ */

CREATE TABLE MealPlan
(
    MealPlanID INT IDENTITY(1,1) PRIMARY KEY,

    PlanName NVARCHAR(50) NOT NULL UNIQUE,
    Description NVARCHAR(200) NULL
);
GO


/* ============================================================
   4. ROOM STATUS
   Current possible states of a room
   ============================================================ */

CREATE TABLE RoomStatus
(
    RoomStatusID INT IDENTITY(1,1) PRIMARY KEY,

    StatusName NVARCHAR(50) NOT NULL UNIQUE
);
GO


/* ============================================================
   5. BOOKING
   Booking channel / method and its discount
   ============================================================ */

CREATE TABLE Booking
(
    BookingID INT IDENTITY(1,1) PRIMARY KEY,

    BookingMethod NVARCHAR(50) NOT NULL UNIQUE,

    DiscountPercentage DECIMAL(5,2) NOT NULL
        CONSTRAINT DF_Booking_Discount
        DEFAULT 0,

    CONSTRAINT CK_Booking_Discount
        CHECK (DiscountPercentage BETWEEN 0 AND 100)
);
GO


/* ============================================================
   6. SERVICE
   Catalog of hotel services

   IncludedMinutes / OverusePricePerHour are mainly intended
   for services such as SPA Access where usage beyond the
   included time is charged extra.
   ============================================================ */

CREATE TABLE Service
(
    ServiceID INT IDENTITY(1,1) PRIMARY KEY,

    ServiceName NVARCHAR(100) NOT NULL UNIQUE,

    Category NVARCHAR(50) NOT NULL,

    UnitPrice DECIMAL(10,2) NOT NULL,

    Description NVARCHAR(255) NULL,

    DefaultDurationMinutes INT NULL,

    IncludedMinutes INT NULL,

    OverusePricePerHour DECIMAL(10,2) NULL,

    CONSTRAINT CK_Service_UnitPrice
        CHECK (UnitPrice >= 0),

    CONSTRAINT CK_Service_Duration
        CHECK
        (
            DefaultDurationMinutes IS NULL
            OR DefaultDurationMinutes > 0
        ),

    CONSTRAINT CK_Service_IncludedMinutes
        CHECK
        (
            IncludedMinutes IS NULL
            OR IncludedMinutes >= 0
        ),

    CONSTRAINT CK_Service_OverusePrice
        CHECK
        (
            OverusePricePerHour IS NULL
            OR OverusePricePerHour >= 0
        )
);
GO


/* ============================================================
   7. GUEST
   ============================================================ */

CREATE TABLE Guest
(
    GuestID INT IDENTITY(1,1) PRIMARY KEY,

    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,

    Gender NVARCHAR(20) NULL,

    PhoneNumber NVARCHAR(30) NULL,
    Email NVARCHAR(255) NULL UNIQUE,

    DateOfBirth DATE NULL,
    Nationality NVARCHAR(100) NULL,
    Address NVARCHAR(255) NULL,

    LoyaltyPoints INT NOT NULL
        CONSTRAINT DF_Guest_LoyaltyPoints
        DEFAULT 0,

    CONSTRAINT CK_Guest_LoyaltyPoints
        CHECK (LoyaltyPoints >= 0)
);
GO


/* ============================================================
   8. SHIFT
   Catalog of employee shifts
   ============================================================ */

CREATE TABLE Shift
(
    ShiftID INT IDENTITY(1,1) PRIMARY KEY,

    ShiftName NVARCHAR(50) NOT NULL UNIQUE,

    StartTime TIME NOT NULL,
    EndTime TIME NOT NULL
);
GO


/* ============================================================
   9. EMPLOYEE ROLE
   ============================================================ */

CREATE TABLE EmployeeRole
(
    RoleID INT IDENTITY(1,1) PRIMARY KEY,

    RoleName NVARCHAR(50) NOT NULL UNIQUE,
    Description NVARCHAR(200) NULL
);
GO


/* ============================================================
   10. DEPARTMENT
   ============================================================ */

CREATE TABLE Department
(
    DepartmentID INT IDENTITY(1,1) PRIMARY KEY,

    DepartmentName NVARCHAR(50) NOT NULL UNIQUE,
    Description NVARCHAR(200) NULL
);
GO


/* ============================================================
   11. ROOM
   RoomStatusID represents CURRENT room status.
   History is stored separately in RoomStatusHistory.
   ============================================================ */

CREATE TABLE Room
(
    RoomID INT IDENTITY(1,1) PRIMARY KEY,

    RoomStatusID INT NOT NULL,
    RoomCategoryID INT NOT NULL,

    RoomNumber INT NOT NULL UNIQUE,

    Floor INT NOT NULL,

    ViewType NVARCHAR(50) NOT NULL,

    CONSTRAINT FK_Room_RoomStatus
        FOREIGN KEY (RoomStatusID)
        REFERENCES RoomStatus(RoomStatusID),

    CONSTRAINT FK_Room_RoomCategory
        FOREIGN KEY (RoomCategoryID)
        REFERENCES RoomCategory(CategoryID),

    CONSTRAINT CK_Room_Floor
        CHECK (Floor >= 0)
);
GO


/* ============================================================
   12. EMPLOYEE
   ============================================================ */

CREATE TABLE Employee
(
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,

    EmployeeRoleID INT NOT NULL,
    DepartmentID INT NOT NULL,

    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,

    PhoneNumber NVARCHAR(30) NULL,

    Email NVARCHAR(255) NOT NULL UNIQUE,

    HireDate DATE NOT NULL,

    Status NVARCHAR(30) NOT NULL,

    Salary DECIMAL(10,2) NOT NULL,

    CONSTRAINT FK_Employee_EmployeeRole
        FOREIGN KEY (EmployeeRoleID)
        REFERENCES EmployeeRole(RoleID),

    CONSTRAINT FK_Employee_Department
        FOREIGN KEY (DepartmentID)
        REFERENCES Department(DepartmentID),

    CONSTRAINT CK_Employee_Salary
        CHECK (Salary >= 0),

    CONSTRAINT CK_Employee_Status
        CHECK (Status IN ('Active', 'Inactive'))
);
GO


/* ============================================================
   13. EMPLOYEE SHIFT
   Employee work schedule.

   One employee can have at most one shift on the same date.
   ============================================================ */

CREATE TABLE EmployeeShift
(
    EmployeeShiftID INT IDENTITY(1,1) PRIMARY KEY,

    EmployeeID INT NOT NULL,
    ShiftID INT NOT NULL,

    WorkDate DATE NOT NULL,

    CONSTRAINT FK_EmployeeShift_Employee
        FOREIGN KEY (EmployeeID)
        REFERENCES Employee(EmployeeID),

    CONSTRAINT FK_EmployeeShift_Shift
        FOREIGN KEY (ShiftID)
        REFERENCES Shift(ShiftID),

    CONSTRAINT UQ_EmployeeShift
        UNIQUE (EmployeeID, WorkDate)
);

/* ============================================================
   14. RATE PLAN

   Price per night depends on:

       Room Category
       + Season
       + Meal Plan
       = Price Per Night

   ReservationPolicy is intentionally NOT included.
   ============================================================ */

CREATE TABLE RatePlan
(
    RatePlanID INT IDENTITY(1,1) PRIMARY KEY,

    CategoryID INT NOT NULL,
    SeasonID INT NOT NULL,
    MealPlanID INT NOT NULL,

    PricePerNight DECIMAL(10,2) NOT NULL,

    CONSTRAINT FK_RatePlan_RoomCategory
        FOREIGN KEY (CategoryID)
        REFERENCES RoomCategory(CategoryID),

    CONSTRAINT FK_RatePlan_Season
        FOREIGN KEY (SeasonID)
        REFERENCES Season(SeasonID),

    CONSTRAINT FK_RatePlan_MealPlan
        FOREIGN KEY (MealPlanID)
        REFERENCES MealPlan(MealPlanID),

    CONSTRAINT CK_RatePlan_Price
        CHECK (PricePerNight > 0),

    CONSTRAINT UQ_RatePlan
        UNIQUE
        (
            CategoryID,
            SeasonID,
            MealPlanID
        )
);
GO


/* ============================================================
   15. RESERVATION

   ReservationDate -> automatically generated
   ReservationStatus -> starts as Confirmed

   ActualCheckIn / ActualCheckOut / CancellationDate
   remain NULL until the corresponding event occurs.

   MealPlan is obtained through RatePlan.
   Discount is obtained through Booking.
   ============================================================ */

CREATE TABLE Reservation
(
    ReservationID INT IDENTITY(1,1) PRIMARY KEY,

    GuestID INT NOT NULL,
    RoomID INT NOT NULL,

    EmployeeID INT NULL,

    BookingID INT NOT NULL,
    RatePlanID INT NOT NULL,

    ReservationDate DATETIME2 NOT NULL
        CONSTRAINT DF_Reservation_Date
        DEFAULT SYSDATETIME(),

    CheckIn DATETIME2 NOT NULL,
    CheckOut DATETIME2 NOT NULL,

    ActualCheckIn DATETIME2 NULL,
    ActualCheckOut DATETIME2 NULL,

    CancellationDate DATETIME2 NULL,

    NumberOfGuests INT NOT NULL,

    ReservationStatus NVARCHAR(20) NOT NULL
        CONSTRAINT DF_Reservation_Status
        DEFAULT 'Confirmed',

    CONSTRAINT FK_Reservation_Guest
        FOREIGN KEY (GuestID)
        REFERENCES Guest(GuestID),

    CONSTRAINT FK_Reservation_Room
        FOREIGN KEY (RoomID)
        REFERENCES Room(RoomID),

    CONSTRAINT FK_Reservation_Employee
        FOREIGN KEY (EmployeeID)
        REFERENCES Employee(EmployeeID),

    CONSTRAINT FK_Reservation_Booking
        FOREIGN KEY (BookingID)
        REFERENCES Booking(BookingID),

    CONSTRAINT FK_Reservation_RatePlan
        FOREIGN KEY (RatePlanID)
        REFERENCES RatePlan(RatePlanID),

    CONSTRAINT CK_Reservation_Dates
        CHECK (CheckOut > CheckIn),

    CONSTRAINT CK_Reservation_NumberOfGuests
        CHECK (NumberOfGuests > 0),

    CONSTRAINT CK_Reservation_Status
        CHECK
        (
            ReservationStatus IN
            (
                'Confirmed',
                'Checked In',
                'Completed',
                'Cancelled',
                'No Show'
            )
        ),

    CONSTRAINT CK_Reservation_ActualDates
        CHECK
        (
            ActualCheckOut IS NULL
            OR ActualCheckIn IS NOT NULL
        )
);
GO



/* ============================================================
   16. SERVICE USAGE

   A service can first be Pending and later Completed.

   UsageDate -> automatically generated
   OrderStatus -> Pending by default

   DurationMinutes is used where relevant, especially SPA.

   Completed ServiceUsage will later create BillItem
   automatically through business logic / trigger.
   ============================================================ */

CREATE TABLE ServiceUsage
(
    UsageID INT IDENTITY(1,1) PRIMARY KEY,

    ServiceID INT NOT NULL,
    ReservationID INT NOT NULL,

    Quantity INT NOT NULL,

    DurationMinutes INT NULL,

    UsageDate DATETIME2 NOT NULL
        CONSTRAINT DF_ServiceUsage_Date
        DEFAULT SYSDATETIME(),

    OrderStatus NVARCHAR(20) NOT NULL
        CONSTRAINT DF_ServiceUsage_Status
        DEFAULT 'Pending',

    EmployeeID INT NULL,

    CONSTRAINT FK_ServiceUsage_Service
        FOREIGN KEY (ServiceID)
        REFERENCES Service(ServiceID),

    CONSTRAINT FK_ServiceUsage_Reservation
        FOREIGN KEY (ReservationID)
        REFERENCES Reservation(ReservationID),

    CONSTRAINT FK_ServiceUsage_Employee
        FOREIGN KEY (EmployeeID)
        REFERENCES Employee(EmployeeID),

    CONSTRAINT CK_ServiceUsage_Quantity
        CHECK (Quantity > 0),

    CONSTRAINT CK_ServiceUsage_Duration
        CHECK
        (
            DurationMinutes IS NULL
            OR DurationMinutes > 0
        ),

    CONSTRAINT CK_ServiceUsage_Status
        CHECK
        (
            OrderStatus IN
            (
                'Pending',
                'In Progress',
                'Completed',
                'Cancelled'
            )
        )
);
GO


/* ============================================================
   17. BILL

   One reservation can have at most one bill.

   TotalAmount is intentionally NOT computed automatically.
   It is maintained (e.g. via trigger/business logic) from
   the sum of related BillItem rows.
   ============================================================ */

CREATE TABLE Bill
(
    BillID INT IDENTITY(1,1) PRIMARY KEY,

    ReservationID INT NOT NULL,

    BillDate DATETIME2 NOT NULL
        CONSTRAINT DF_Bill_Date
        DEFAULT SYSDATETIME(),

    BillStatus NVARCHAR(20) NOT NULL
        CONSTRAINT DF_Bill_Status
        DEFAULT 'Unpaid',

    TotalAmount DECIMAL(10,2) NOT NULL
        CONSTRAINT DF_Bill_TotalAmount
        DEFAULT 0,

    CONSTRAINT FK_Bill_Reservation
        FOREIGN KEY (ReservationID)
        REFERENCES Reservation(ReservationID),

    CONSTRAINT UQ_Bill_Reservation
        UNIQUE (ReservationID),

    CONSTRAINT CK_Bill_TotalAmount
        CHECK (TotalAmount >= 0)
);
GO
ALTER TABLE dbo.Bill
ADD CONSTRAINT CK_Bill_Status
CHECK
(
    BillStatus IN
    (
        'Unpaid',
        'Paid',
        'Cancelled'
    )
);
GO

use HotelManagement


/* ============================================================
   18. BILL ITEM

   Individual financial items belonging to a bill.

   Possible sources:
       Accommodation
       Completed ServiceUsage
       SPA Overuse
       Cancellation Fee
       No Show Fee

   TotalPrice is automatically calculated.

   ServiceUsageID is NULL when the item does not originate
   from one individual ServiceUsage.
   ============================================================ */

CREATE TABLE BillItem
(
    BillItemID INT IDENTITY(1,1) PRIMARY KEY,

    BillID INT NOT NULL,

    ServiceUsageID INT NULL,

    ItemType NVARCHAR(30) NOT NULL,

    Description NVARCHAR(150) NOT NULL,

    Quantity INT NOT NULL,

    UnitPrice DECIMAL(10,2) NOT NULL,

    DiscountPercentage DECIMAL(5,2) NOT NULL
        CONSTRAINT DF_BillItem_Discount
        DEFAULT 0,

    TotalPrice AS
    (
        CAST
        (
            Quantity
            * UnitPrice
            * (1 - DiscountPercentage / 100.0)

            AS DECIMAL(12,2)
        )
    ) PERSISTED,

    CONSTRAINT FK_BillItem_Bill
        FOREIGN KEY (BillID)
        REFERENCES Bill(BillID),

    CONSTRAINT FK_BillItem_ServiceUsage
        FOREIGN KEY (ServiceUsageID)
        REFERENCES ServiceUsage(UsageID),

    CONSTRAINT CK_BillItem_Type
        CHECK
        (
            ItemType IN
            (
                'Accommodation',
                'Service',
                'Spa Overuse',
                'Cancellation Fee',
                'No Show Fee'
            )
        ),

    CONSTRAINT CK_BillItem_Quantity
        CHECK (Quantity > 0),

    CONSTRAINT CK_BillItem_UnitPrice
        CHECK (UnitPrice >= 0),

    CONSTRAINT CK_BillItem_Discount
        CHECK (DiscountPercentage BETWEEN 0 AND 100),

    -- One ServiceUsage cannot be charged twice
    CONSTRAINT UQ_BillItem_ServiceUsage
        UNIQUE (ServiceUsageID)
);
GO


/* ============================================================
   19. PAYMENT

   Multiple payments are allowed for one bill.
   This supports partial payments if needed.
   ============================================================ */
CREATE TABLE Payment
(
    PaymentID INT IDENTITY(1,1) PRIMARY KEY,

    BillID INT NOT NULL,

    PaymentMethodID INT NOT NULL,

    Amount DECIMAL(10,2) NOT NULL,

    PaymentDate DATETIME2 NOT NULL
        CONSTRAINT DF_Payment_Date
        DEFAULT SYSDATETIME(),

    CONSTRAINT FK_Payment_Bill
        FOREIGN KEY (BillID)
        REFERENCES Bill(BillID),

    CONSTRAINT FK_Payment_PaymentMethod
        FOREIGN KEY (PaymentMethodID)
        REFERENCES PaymentMethod(PaymentMethodID),

    CONSTRAINT CK_Payment_Amount
        CHECK (Amount > 0)
);
GO


/* ============================================================
   20. NOTIFICATION

   Actual email integration is not required.
   Notifications can be logged/simulated here.
   ============================================================ */

CREATE TABLE Notification
(
    NotificationID INT IDENTITY(1,1) PRIMARY KEY,

    ReservationID INT NOT NULL,

    NotificationType NVARCHAR(50) NOT NULL,

    NotificationReason NVARCHAR(100) NOT NULL,

    NotificationStatus NVARCHAR(50) NOT NULL
        CONSTRAINT DF_Notification_Status
        DEFAULT 'Pending',
    Message NVARCHAR(500) NOT NULL,

    SentAt DATETIME2 NULL,

    CONSTRAINT FK_Notification_Reservation
        FOREIGN KEY (ReservationID)
        REFERENCES Reservation(ReservationID),



    CONSTRAINT CK_Notification_Type
        CHECK
        (
            NotificationType IN ('Email', 'SMS')
        ),

    CONSTRAINT CK_Notification_Status
        CHECK
        (
            NotificationStatus IN
            (
                'Pending',
                'Sent',
                'Failed'
            )
        )
);
GO


/* ============================================================
   21. ROOM STATUS HISTORY

   Stores historical room-status changes.

   EmployeeID is nullable because some status changes can be
   generated automatically by the system.
   ============================================================ */

CREATE TABLE RoomStatusHistory
(
    RoomStatusHistoryID INT IDENTITY(1,1) PRIMARY KEY,

    RoomID INT NOT NULL,

    RoomStatusID INT NOT NULL,

    EmployeeID INT NULL,

    ChangeDateTime DATETIME2 NOT NULL
        CONSTRAINT DF_RoomStatusHistory_Date
        DEFAULT SYSDATETIME(),

    CONSTRAINT FK_RoomStatusHistory_Room
        FOREIGN KEY (RoomID)
        REFERENCES Room(RoomID),

    CONSTRAINT FK_RoomStatusHistory_RoomStatus
        FOREIGN KEY (RoomStatusID)
        REFERENCES RoomStatus(RoomStatusID),

    CONSTRAINT FK_RoomStatusHistory_Employee
        FOREIGN KEY (EmployeeID)
        REFERENCES Employee(EmployeeID)
);
GO


/* ============================================================
   22. GUEST FEEDBACK
   ============================================================ */

CREATE TABLE GuestFeedback
(
    FeedbackID INT IDENTITY(1,1) PRIMARY KEY,

    ReservationID INT NOT NULL,

    Rating INT NOT NULL,

    Comment NVARCHAR(255) NULL,

    FeedbackType AS
    (
        CASE
            WHEN Rating <= 2 THEN 'Negative'
            WHEN Rating = 3 THEN 'Neutral'
            ELSE 'Positive'
        END
    ) PERSISTED,

    Suggestion NVARCHAR(255) NULL,

    SentAt DATETIME2 NOT NULL
        CONSTRAINT DF_GuestFeedback_Date
        DEFAULT SYSDATETIME(),

    CONSTRAINT FK_GuestFeedback_Reservation
        FOREIGN KEY (ReservationID)
        REFERENCES Reservation(ReservationID),

    CONSTRAINT CK_GuestFeedback_Rating
        CHECK (Rating BETWEEN 1 AND 5)
);
GO


-- Reservation Charge 

CREATE TABLE ReservationCharge
(
    ReservationChargeID INT IDENTITY(1,1) PRIMARY KEY,

    BillID INT NOT NULL,

    ChargeType NVARCHAR(30) NOT NULL,

    Amount DECIMAL(10,2) NOT NULL,

    CreatedAt DATETIME2 NOT NULL
        CONSTRAINT DF_ReservationCharge_CreatedAt
        DEFAULT SYSDATETIME(),

    CONSTRAINT FK_ReservationCharge_Bill
        FOREIGN KEY (BillID)
        REFERENCES Bill(BillID),

    CONSTRAINT CK_ReservationCharge_Type
        CHECK
        (
            ChargeType IN
            (
                'Accommodation',
                'Cancellation Fee',
                'No Show Fee'
            )
        ),

    CONSTRAINT CK_ReservationCharge_Amount
        CHECK (Amount >= 0)
);
GO




ALTER TABLE ReservationCharge
ADD CONSTRAINT CK_ReservationCharge_ChargeType
CHECK (ChargeType IN ('Accommodation', 'Cancellation', 'No Show'));
GO

-- Service Charges

CREATE TABLE ServiceCharge
(
    ServiceChargeID INT IDENTITY(1,1) PRIMARY KEY,

    BillID INT NOT NULL,

    ServiceUsageID INT NOT NULL,

    Amount DECIMAL(10,2) NOT NULL,

    CreatedAt DATETIME2 NOT NULL
        CONSTRAINT DF_ServiceCharge_CreatedAt
        DEFAULT SYSDATETIME(),

    CONSTRAINT FK_ServiceCharge_Bill
        FOREIGN KEY (BillID)
        REFERENCES Bill(BillID),

    CONSTRAINT FK_ServiceCharge_ServiceUsage
        FOREIGN KEY (ServiceUsageID)
        REFERENCES ServiceUsage(UsageID),

    CONSTRAINT UQ_ServiceCharge_ServiceUsage
        UNIQUE (ServiceUsageID),

    CONSTRAINT CK_ServiceCharge_Amount
        CHECK (Amount >= 0)
);
GO

   -- Payment method
    CREATE TABLE PaymentMethod
    (
        PaymentMethodID INT IDENTITY(1,1) PRIMARY KEY,

        MethodName NVARCHAR(50) NOT NULL UNIQUE
    );
    GO

    INSERT INTO PaymentMethod (MethodName)
    VALUES
    ('Cash'),
    ('Credit Card'),
    ('Debit Card'),
    ('Bank Transfer');
   GO

---- country


CREATE TABLE Country (
    CountryID INT IDENTITY(1,1) PRIMARY KEY,
    CountryName VARCHAR(100) NOT NULL UNIQUE
);

ALTER TABLE Guest ADD CountryID INT NULL;

ALTER TABLE Guest ADD CONSTRAINT FK_Guest_Country
    FOREIGN KEY (CountryID) REFERENCES Country(CountryID);