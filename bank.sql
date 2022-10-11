CREATE DATABASE BankDatabase
GO

USE BankDatabase

DROP TABLE IF EXISTS cards
DROP TABLE IF EXISTS account
DROP TABLE IF EXISTS social_status
DROP TABLE IF EXISTS branch
DROP TABLE IF EXISTS bank
DROP TABLE IF EXISTS city
GO


--USE tmpDatabase

-- 0
CREATE TABLE bank
(bank_id INT IDENTITY PRIMARY KEY,
bank_name VARCHAR(50) UNIQUE NOT NULL);

INSERT INTO bank(bank_name) VALUES
('БЕЛАРУСЬБАНК'),
('БЕЛАГРОПРОМБАНК'),
('ПРИОР-БАНК'),
('БЕЛПРОМСТРОЙБАНК'),
('БЕЛИНВЕСТБАНК')

CREATE TABLE city
(city_id INT IDENTITY PRIMARY KEY,
city_name VARCHAR(30) UNIQUE NOT NULL);

INSERT INTO city(city_name) VALUES
('Минск'),
('Могилёв'),
('Полоцк'),
('Брест'),
('Борисов')

CREATE TABLE branch
(branch_id INT IDENTITY PRIMARY KEY,
bank_id INT FOREIGN KEY REFERENCES bank(bank_id),
city_id INT FOREIGN KEY REFERENCES city(city_id),
branch_name VARCHAR(50) UNIQUE NOT NULL);

INSERT INTO branch(bank_id, city_id, branch_name) VALUES
(1, 1, 'БеларусьБанк-01'),
(1, 2, 'БеларусьБанк-02'),
(3, 1, 'ПриорБанк-92'),
(3, 5, 'ПриорБанк-31'),
(5, 2, 'БелинвестБанк-50'),
(5, 5, 'БелинвестБанк-32'),
(5, 1, 'БелинвестБанк-14'),
(2, 5, 'БелагропромБанк-32'),
(4, 4, 'БелпромстройБанк-04')

CREATE TABLE social_status
(status_id INT IDENTITY PRIMARY KEY,
status_name VARCHAR(20) NOT NULL);

INSERT INTO social_status(status_name) VALUES
('Рабочий'),
('Инвалид'),
('Пенсионер'),
('Безработный'),
('Студент')

CREATE TABLE account
(account_id INT IDENTITY PRIMARY KEY,
bank_id INT FOREIGN KEY REFERENCES bank(bank_id),
status_id INT FOREIGN KEY REFERENCES social_status(status_id),
passport_data VARCHAR(20) UNIQUE NOT NULL,
account_name VARCHAR(20) NOT NULL,
account_surname VARCHAR(20) NOT NULL,
balance MONEY NOT NULL);


INSERT INTO account(bank_id, status_id, passport_data, account_name, account_surname, balance) VALUES
(1, 1,'sf28', 'Иванов', 'Алексей',  200),
(2, 1, 'rg19', 'Смирнов', 'Даниил',  350),
(1, 1, 'ka56', 'Петров', 'Денис', 50),
(3, 2, 'hg92', 'Новиков', 'Владимир', 400),
(3, 3, 'ak45', 'Морозов', 'Егор', 270),
(4, 3, 'jy28', 'Попов', 'Владислав', 460),
(5, 3,'hg02', 'Михайлов', 'Кирилл', 600),
(5, 2,'ba97', 'Павлов', 'Роман', 420)

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
SELECT bank_name
FROM bank
LEFT JOIN branch ON bank.bank_id = branch.bank_id
LEFT JOIN city ON branch.city_id = city.city_id
WHERE city.city_name = 'Минск'

-- 2
SELECT C.card_id AS card_id, A.account_name AS account_name, A.account_surname AS account_surname, C.balance AS balance
FROM cards AS C
LEFT JOIN account AS A ON C.account_id = A.account_id
LEFT JOIN bank AS B ON B.bank_id = A.bank_id

-- 3
SELECT A.account_id AS account_id, A.account_name AS name, A.account_surname AS surname, AVG(A.balance) - ISNULL(SUM(C.balance), 0) AS differences
FROM cards AS C
FULL JOIN account AS A ON A.account_id = C.account_id
GROUP BY A.account_id, A.account_name, A.account_surname
HAVING AVG(A.balance) - ISNULL(SUM(C.balance), 0) != 0


