
MongoDB -> PostgreSQL Conversion

db.users.find({name:"Jeyanth",cgpa:{"$lt":9}},{ name:1})                   

SELECT  name FROM users WHERE name = "Jeyanth" AND cgpa < 9;


Features handled:

Selection
Projection
Conversion of Clauses (like AND , WHERE )
Conditional operators

