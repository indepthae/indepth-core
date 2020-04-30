Payment.connection.execute("UPDATE `payments` SET `status_description` = 1 WHERE `status` = 1")
Payment.connection.execute("UPDATE `payments` SET `status_description` = 3 WHERE `status` = 0")

