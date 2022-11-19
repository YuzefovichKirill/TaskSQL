--CREATE DATABASE BankDatabase
--GO


USE BankDatabase

DROP TABLE IF EXISTS cards
DROP TABLE IF EXISTS account
DROP TABLE IF EXISTS social_status
DROP TABLE IF EXISTS branch
DROP TABLE IF EXISTS bank
DROP TABLE IF EXISTS city
DROP PROCEDURE IF EXISTS AddMoneyByStatus
DROP PROCEDURE IF EXISTS TransferMoney
GO


-- 0
CREATE TABLE bank
(bank_id INT IDENTITY PRIMARY KEY,
bank_name VARCHAR(50) UNIQUE NOT NULL);

INSERT INTO bank(bank_name) VALUES
('Belarusbank'),
('Belagroprombank'),
('Priorbank'),
('Sberbank'),
('Belinvestbank')

CREATE TABLE city
(city_id INT IDENTITY PRIMARY KEY,
city_name VARCHAR(30) UNIQUE NOT NULL);

INSERT INTO city(city_name) VALUES
('Minsk'),
('Mogilev'),
('Polotsk'),
('Brest'),
('Borisov')

CREATE TABLE branch
(branch_id INT IDENTITY PRIMARY KEY,
bank_id INT FOREIGN KEY REFERENCES bank(bank_id),
city_id INT FOREIGN KEY REFERENCES city(city_id),
branch_name VARCHAR(50) UNIQUE NOT NULL);

INSERT INTO branch(bank_id, city_id, branch_name) VALUES
(1, 1, 'Belarusbank-01'),
(1, 2, 'Belarusbank-02'),
(3, 1, 'Priorbank-92'),
(3, 5, 'Priorbank-31'),
(5, 2, 'Belinvestbank-50'),
(5, 5, 'Belinvestbank-32'),
(5, 1, 'Belinvestbank-14'),
(2, 5, 'Belagroprombank-32'),
(4, 4, 'Sberbank-04')

CREATE TABLE social_status
(status_id INT IDENTITY PRIMARY KEY,
status_name VARCHAR(20) NOT NULL);

INSERT INTO social_status(status_name) VALUES
('Worker'),
('Disabled'),
('Pensioner'),
('Unemployed'),
('Student')

CREATE TABLE account
(account_id INT IDENTITY PRIMARY KEY,
bank_id INT FOREIGN KEY REFERENCES bank(bank_id),
status_id INT FOREIGN KEY REFERENCES social_status(status_id),
passport_data VARCHAR(20) UNIQUE NOT NULL,
account_name VARCHAR(20) NOT NULL,
account_surname VARCHAR(20) NOT NULL,
balance MONEY NOT NULL);

INSERT INTO account(bank_id, status_id, passport_data, account_surname, account_name, balance) VALUES
(1, 1,'sf28', 'Ivanov', 'Alexei',  200),
(2, 1, 'rg19', 'Smirnov', 'Daniel',  350),
(1, 1, 'ka56', 'Petrov', 'Denis', 50),
(3, 2, 'hg92', 'Novikov', 'Vladimir', 400),
(3, 3, 'ak45', 'Morozov', 'Egor', 270),
(4, 3, 'jy28', 'Popov', 'Vladislav', 460),
(5, 3, 'hg02', 'Mikhailov', 'Kirill', 600),
(5, 2, 'ba97', 'Pavlov', 'Roman', 420)

CREATE TABLE cards
(card_id INT IDENTITY PRIMARY KEY,
account_id INT FOREIGN KEY REFERENCES account(account_id),
balance MONEY NOT NULL);

INSERT INTO cards(account_id, balance) VALUES
(1, 50),
(1, 150),
(2, 250),
(4, 200),
(6, 210),
(6, 250),
(7, 350),
(8, 210),
(8, 120)


-- 1
SELECT 
	bank_name
FROM bank
LEFT JOIN branch 
	ON bank.bank_id = branch.bank_id
LEFT JOIN city 
	ON branch.city_id = city.city_id
WHERE city.city_name = 'Minsk'


-- 2
SELECT	
	C.card_id AS card_id, 
	A.account_name AS account_name, 
	A.account_surname AS account_surname, 
	C.balance AS balance
FROM cards AS C
LEFT JOIN account AS A 
	ON C.account_id = A.account_id
LEFT JOIN bank AS B 
	ON B.bank_id = A.bank_id


-- 3
SELECT	
	A.account_id AS account_id, 
	AVG(A.balance) - ISNULL(SUM(C.balance), 0) AS differences
FROM cards AS C
FULL JOIN account AS A 
	ON A.account_id = C.account_id
GROUP BY A.account_id
HAVING AVG(A.balance) - ISNULL(SUM(C.balance), 0) != 0


-- 4.1
SELECT	
	SC.status_name AS social_status, 
	COUNT(*) AS num_of_cards
FROM cards AS C
LEFT JOIN account AS A 
	ON A.account_id = C.account_id
LEFT JOIN social_status AS SC 
	ON A.status_id = SC.status_id
GROUP BY SC.status_name

-- 4.2
SELECT	
	SC.status_name AS social_status, 
	internal.num_of_cards AS num_of_cards
FROM social_status AS SC
RIGHT JOIN 
	(SELECT A.status_id, 
			COUNT(*) AS num_of_cards 
	FROM account AS A 
	RIGHT JOIN cards AS C 
		ON A.account_id = C.account_id
	GROUP BY A.status_id) AS internal 
	ON internal.status_id = SC.status_id
GO


-- 5
CREATE PROCEDURE AddMoneyByStatus
@status_id INT
AS
BEGIN
	IF NOT EXISTS ( SELECT * FROM social_status WHERE social_status.status_id = @status_id)
	BEGIN
		RAISERROR('Status with this id doesnt exist', 16, 1)
		RETURN
	END

	IF NOT EXISTS ( SELECT * FROM account WHERE status_id = @status_id) 
	BEGIN
		RAISERROR('no one account have this status id', 16, 1)
		RETURN
	END

	UPDATE account
	SET balance = balance + 10
	WHERE status_id = @status_id
END
GO

SELECT * FROM account

EXEC AddMoneyByStatus @status_id = 1

SELECT * FROM account


-- 6
SELECT 
	A.account_id AS account_id, 
	AVG(A.balance) - ISNULL(SUM(C.balance), 0) AS available_money
FROM cards AS C
FULL JOIN account AS A 
	ON A.account_id = C.account_id
GROUP BY A.account_id
GO


-- 7
CREATE PROCEDURE TransferMoney
@account_id INT,
@card_id INT,
@sum INT
AS
BEGIN
	IF NOT EXISTS (SELECT * FROM account WHERE account.account_id = @account_id)
	BEGIN
		RAISERROR('Account doesnt exist', 16, 1)
		RETURN
	END

	IF NOT EXISTS (SELECT * FROM cards WHERE cards.card_id = @card_id)
	BEGIN
		RAISERROR('Card doesnt exist', 16, 1)
		RETURN
	END

	IF NOT EXISTS (SELECT * FROM cards WHERE cards.account_id = @account_id AND cards.card_id = @card_id)
	BEGIN
		RAISERROR('The card is not belongs to this account', 16, 1)
		RETURN
	END

	DECLARE @diff INT = 0

	SET @diff = (SELECT AVG(A.balance) - ISNULL(SUM(C.balance), 0) 
				FROM cards AS C
				LEFT JOIN account AS A 
					ON A.account_id = C.account_id
				WHERE A.account_id = @account_id
				GROUP BY A.account_id) - @sum;

	IF (@diff < 0)
	BEGIN
		RAISERROR('Account doesnt have enough money to transact', 16, 1)
		RETURN
	END
	
	BEGIN TRANSACTION
		UPDATE cards
		SET balance = balance + @sum
		WHERE card_id = @card_id

		IF(@@ERROR != 0)
			ROLLBACK	
	COMMIT
END
GO

SELECT * FROM cards

EXEC TransferMoney @account_id = 2, @card_id = 3, @sum = 5

SELECT * FROM cards
GO


-- 8
CREATE TRIGGER account_insert_update
ON account
AFTER INSERT, UPDATE
AS
BEGIN
	DECLARE @diff INT = 0

	SET @diff = (SELECT  
					ISNULL(AVG(A.balance), 0) - ISNULL(SUM(C.balance), 0) 
				FROM account AS A 
				INNER JOIN inserted AS i
					ON A.account_id = i.account_id
				RIGHT JOIN cards AS C 
					ON A.account_id = C.account_id
				WHERE A.account_id = i.account_id 
				GROUP BY A.account_id);

	IF (@diff < 0)
	BEGIN
		RAISERROR('account balance < sum of cards balance)', 16, 1)
		ROLLBACK
	END

	IF EXISTS (SELECT * FROM inserted AS I WHERE I.balance < 0)
	BEGIN
		RAISERROR('account balance cant be negative', 16, 1)
		ROLLBACK
	END
END
GO

SELECT * FROM cards

SELECT * from account
GO

UPDATE account
SET balance = 5
WHERE account_id = 1
GO

SELECT * FROM cards

SELECT * FROM account
GO

INSERT INTO account(bank_id, status_id, passport_data, account_surname, account_name, balance) VALUES
(1, 1, 'gh27', 'Petrovich', 'Peter', -5)
GO

SELECT * FROM cards

SELECT * FROM account
GO

CREATE TRIGGER cards_insert_update
ON cards
AFTER INSERT, UPDATE
AS
BEGIN
	DECLARE @diff INT = 0

	SET @diff = (SELECT 
					AVG(A.balance) - ISNULL(SUM(C.balance), 0) 
				FROM 
					inserted as I, 
					cards AS C
				LEFT JOIN account AS A 
					ON A.account_id = C.account_id
				WHERE I.account_id = A.account_id
				GROUP BY A.account_id);
	
	IF (@diff < 0)
	BEGIN
		RAISERROR('account balance < sum of cards balance)', 16, 1)
		ROLLBACK
	END

	IF EXISTS (SELECT * FROM inserted AS I WHERE I.balance < 0)
	BEGIN
		RAISERROR('card balance cant be negative', 16, 1)
		ROLLBACK
	END
END
GO

SELECT * FROM cards
GO

UPDATE cards
SET balance = 120
WHERE card_id = 1
GO

SELECT * FROM cards
GO

INSERT INTO cards(account_id, balance) VALUES
(1, 15)
GO

SELECT * FROM cards
GO