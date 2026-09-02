USE HotelManagement;
GO


--  REFERENCE TABLES

CREATE TABLE Department
(
    DepartmentID   INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentName NVARCHAR(50) NOT NULL UNIQUE,
    Description    NVARCHAR(200)
);
GO

CREATE TABLE EmployeeRole
(
    RoleID      INT IDENTITY(1,1) PRIMARY KEY,
    RoleName    NVARCHAR(50) NOT NULL UNIQUE,
    Description NVARCHAR(50)
);
GO

CREATE TABLE MealPlan
(
    MealPlanID  INT IDENTITY(1,1) PRIMARY KEY,
    PlanName    NVARCHAR(50) NOT NULL UNIQUE,
    Description NVARCHAR(200)
);
GO

CREATE TABLE Season
(
    SeasonID   INT IDENTITY(1,1) PRIMARY KEY,
    SeasonName NVARCHAR(50) NOT NULL UNIQUE,
    StartDate  DATE NOT NULL,
    EndDate    DATE NOT NULL
);
GO

UPDATE Season
SET SeasonName = 'Winter Season'
WHERE SeasonID = 1;

UPDATE Season
SET SeasonName = 'Summer Season'
WHERE SeasonID = 3;
GO

CREATE TABLE Shift
(
    ShiftID   INT IDENTITY(1,1) PRIMARY KEY,
    ShiftName NVARCHAR(50) NOT NULL UNIQUE,
    StartTime TIME NOT NULL,
    EndTime   TIME NOT NULL
);
GO

CREATE TABLE Booking
(
    BookingID      INT IDENTITY(1,1) PRIMARY KEY,
    SourceName     NVARCHAR(50) NOT NULL UNIQUE,
    CommissionRate INT,
    ContactInfo    NVARCHAR(50) NOT NULL
);
GO

CREATE TABLE RoomStatus
(
    RoomStatusID INT IDENTITY(1,1) PRIMARY KEY,
    StatusName   VARCHAR(20) NOT NULL UNIQUE
);
GO


-- ROOM / SERVICE TABLES

CREATE TABLE RoomCategory
(
    CategoryID    INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName  NVARCHAR(100) NOT NULL UNIQUE,
    Description   NVARCHAR(200),
    PricePerNight DECIMAL(10,2) NOT NULL,
    MaximumGuests INT NOT NULL,
    RoomSize      INT NOT NULL,
    BedType       NVARCHAR(50) NOT NULL,
    NumberOfBeds  INT NOT NULL,
    HasBalcony    BIT NOT NULL
);
GO

CREATE TABLE RoomStatusHistory
(
    RoomStatusHistoryID INT IDENTITY(1,1) PRIMARY KEY,
    RoomID              INT NOT NULL,
    EmployeeID          INT NOT NULL,
    RoomStatusID        INT NOT NULL,

    ChangeDateTime      DATETIME NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE Room
(
    RoomID         INT IDENTITY(1,1) PRIMARY KEY,
    RoomStatusID   INT NOT NULL,
    RoomCategoryID INT NOT NULL,
    RoomNumber     INT NOT NULL UNIQUE,
    Floor          INT NOT NULL,
    ViewType       NVARCHAR(50) NOT NULL,
    Free           BIT NOT NULL
);
GO

CREATE TABLE Service
(
    ServiceID   INT IDENTITY(1,1) PRIMARY KEY,
    Category    NVARCHAR(50) NOT NULL UNIQUE,
    UnitPrice   DECIMAL(10,2) NOT NULL,
    Description NVARCHAR(50) NOT NULL
);
GO


-- GUEST / EMPLOYEE TABLES

CREATE TABLE Guest
(
    GuestID     INT IDENTITY(1,1) PRIMARY KEY,
    FirstName   NVARCHAR(100) NOT NULL,
    LastName    NVARCHAR(100) NOT NULL,
    Gender      NVARCHAR(20),
    PhoneNumber NVARCHAR(30),
    Email       NVARCHAR(255) UNIQUE,
    DateOfBirth DATE,
    Nationality NVARCHAR(100),
    Address     NVARCHAR(255)
);
GO

CREATE TABLE Employee
(
    EmployeeID     INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeRoleID INT NOT NULL,
    DepartmentID   INT NOT NULL,

    FirstName      NVARCHAR(100) NOT NULL,
    LastName       NVARCHAR(100) NOT NULL,

    PhoneNumber    NVARCHAR(30),
    Email          NVARCHAR(255) NOT NULL UNIQUE,

    HireDate       DATE NOT NULL,
    Status         NVARCHAR(30) NOT NULL,
    Salary         DECIMAL(10,2) NOT NULL
);
GO



-- RESERVATION / BILLING

CREATE TABLE Reservation
(
    ReservationID       INT IDENTITY(1,1) PRIMARY KEY,

    RoomID              INT NOT NULL,
    GuestID             INT NOT NULL,
    MealPlanID          INT NOT NULL,
    BookingID           INT NOT NULL,
    ReservationPolicyID INT NOT NULL,

    ReservationStatus   NVARCHAR(50) NOT NULL,
    NumberOfGuests      INT NOT NULL,

    CancellationDate    DATE,
    ReservationDate     DATE NOT NULL,
    CheckIn             DATE NOT NULL,
    CheckOut            DATE NOT NULL,
    BookingDate         DATE NOT NULL,

    DiscountPercentage  DECIMAL(5,2) NOT NULL DEFAULT 0
);
GO

CREATE TABLE Bill
(
    BillID        INT IDENTITY(1,1) PRIMARY KEY,
    ReservationID INT NOT NULL,

    BillStatus    NVARCHAR(50) NOT NULL,
    IssueDate     DATE NOT NULL,
    TotalAmount   DECIMAL(10,2) NOT NULL
);
GO

CREATE TABLE Payment
(
    PaymentID     INT IDENTITY(1,1) PRIMARY KEY,
    BillID        INT NOT NULL,

    PaymentDate   DATE NOT NULL,
    PaymentMethod NVARCHAR(50) NOT NULL,
    PaymentStatus NVARCHAR(50) NOT NULL,
    Amount        DECIMAL(10,2) NOT NULL
);
GO


-- NOTIFICATIONS / FEEDBACK

DROP TABLE IF EXISTS Notification;
GO

CREATE TABLE Notification
(
    NotificationID     INT IDENTITY(1,1) PRIMARY KEY,
    ReservationID      INT NOT NULL,

    NotificationType   VARCHAR(50) NOT NULL,
    NotificationReason VARCHAR(50) NOT NULL,
    NotificationStatus VARCHAR(50) NOT NULL,

    Message            VARCHAR(255) NOT NULL,
    SentAt             DATETIME NOT NULL DEFAULT GETDATE()
);
GO

DROP TABLE IF EXISTS GuestFeedback;
GO

CREATE TABLE GuestFeedback
(
    FeedbackID    INT IDENTITY(1,1) PRIMARY KEY,
    ReservationID INT NOT NULL,

    Rating        INT NOT NULL,
    Comment       VARCHAR(255) NOT NULL,
    FeedbackType  VARCHAR(50) NOT NULL,
    Suggestion    VARCHAR(255),

    SentAt        DATETIME NOT NULL DEFAULT GETDATE()
);
GO


-- EMPLOYEE / SERVICE OPERATIONS

DROP TABLE IF EXISTS EmployeeShift;
GO

CREATE TABLE EmployeeShift
(
    EmployeeShiftID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID      INT NOT NULL,
    ShiftID         INT NOT NULL,
    WorkDate        DATE NOT NULL
);
GO

CREATE TABLE ServiceUsage
(
    UsageID       INT IDENTITY(1,1) PRIMARY KEY,
    ServiceID     INT NOT NULL,
    ReservationID INT NOT NULL,

    Quantity      INT NOT NULL,
    Duration      INT,
    TotalPrice    DECIMAL(10,2) NOT NULL,
    OrderStatus   NVARCHAR(50) NOT NULL
);
GO

