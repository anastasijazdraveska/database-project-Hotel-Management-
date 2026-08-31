USE HotelManagement;
GO

   --  ReservationDetails

CREATE OR ALTER VIEW ReservationDetails
AS
SELECT
    r.ReservationID,

    g.GuestID,
    g.FirstName,
    g.LastName,
    g.PhoneNumber,
    g.Email,

    rm.RoomNumber,

    b.BookingMethod,

    rp.PricePerNight,

    r.CheckIn,
    r.CheckOut,

    r.ActualCheckIn,
    r.ActualCheckOut,

    DATEDIFF(DAY,r.CheckIn,r.CheckOut) AS NumberOfNights,

    r.ReservationStatus

FROM Reservation r

INNER JOIN Guest g
ON r.GuestID = g.GuestID

INNER JOIN Room rm
ON r.RoomID = rm.RoomID

INNER JOIN Booking b
ON r.BookingID = b.BookingID

INNER JOIN RatePlan rp
ON r.RatePlanID = rp.RatePlanID;
GO


   -- EmployeeDetails

CREATE OR ALTER VIEW EmployeeDetails
AS
SELECT

    e.EmployeeID,

    e.FirstName,
    e.LastName,

    d.DepartmentName,

    er.RoleName,

    e.PhoneNumber,
    e.Email,

    e.Status

FROM Employee e

INNER JOIN Department d
ON e.DepartmentID = d.DepartmentID

INNER JOIN EmployeeRole er
ON e.EmployeeRoleID = er.RoleID;
GO


    -- EmployeeSchedule
CREATE OR ALTER VIEW EmployeeSchedule
AS
SELECT

    e.EmployeeID,

    e.FirstName,
    e.LastName,

    es.WorkDate,

    s.ShiftName,
    s.StartTime,
    s.EndTime

FROM Employee e

INNER JOIN EmployeeShift es
ON e.EmployeeID = es.EmployeeID

INNER JOIN Shift s
ON es.ShiftID = s.ShiftID;
GO


    --  GuestDetails

CREATE OR ALTER VIEW GuestDetails
AS
SELECT

    GuestID,
    FirstName,
    LastName,
    PhoneNumber,
    Email

FROM Guest;
GO


    -- RoomDetails

CREATE OR ALTER VIEW RoomDetails
AS
SELECT

    r.RoomID,

    r.RoomNumber,

    r.Floor,

    rc.CategoryName,

    r.ViewType,

    rs.StatusName,

    rc.Description

FROM Room r

INNER JOIN RoomCategory rc
ON r.RoomCategoryID = rc.CategoryID

INNER JOIN RoomStatus rs
ON r.RoomStatusID = rs.RoomStatusID;
GO


    -- ServiceUsageDetails

CREATE OR ALTER VIEW ServiceUsageDetails
AS
SELECT

    su.UsageID,

    g.FirstName + ' ' + g.LastName AS Guest,

    rm.RoomNumber,

    s.ServiceName,

    su.Quantity,

    su.DurationMinutes,

    su.OrderStatus,

    e.FirstName + ' ' + e.LastName AS Employee

FROM ServiceUsage su

INNER JOIN Reservation r
ON su.ReservationID = r.ReservationID

INNER JOIN Guest g
ON r.GuestID = g.GuestID

INNER JOIN Room rm
ON r.RoomID = rm.RoomID

INNER JOIN Service s
ON su.ServiceID = s.ServiceID

LEFT JOIN Employee e
ON su.EmployeeID = e.EmployeeID;
GO


    -- BillDetails

CREATE OR ALTER VIEW BillDetails
AS
SELECT

    b.BillID,

    r.ReservationID,

    g.FirstName + ' ' + g.LastName AS Guest,

    rm.RoomNumber,

    b.BillDate,

    b.TotalAmount,

    b.BillStatus

FROM Bill b

INNER JOIN Reservation r
ON b.ReservationID = r.ReservationID

INNER JOIN Guest g
ON r.GuestID = g.GuestID

INNER JOIN Room rm
ON r.RoomID = rm.RoomID;
GO



    --  RoomStatusHistoryDetails

CREATE OR ALTER VIEW RoomStatusHistoryDetails
AS
SELECT

    rsh.RoomStatusHistoryID,

    rm.RoomNumber,

    rs.StatusName,

    e.FirstName + ' ' + e.LastName AS Employee,

    rsh.ChangeDateTime

FROM RoomStatusHistory rsh

INNER JOIN Room rm
ON rsh.RoomID = rm.RoomID

INNER JOIN RoomStatus rs
ON rsh.RoomStatusID = rs.RoomStatusID

LEFT JOIN Employee e
ON rsh.EmployeeID = e.EmployeeID;
GO