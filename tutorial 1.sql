-- Now we've got some data, let's start to explore the dataset.

-- ### Dataset
-- image::http://dev.assets.neo4j.com.s3.amazonaws.com/wp-content/uploads/Northwind_diagram.jpg[]
-- The Northwind Graph provides us with a rich dataset, but primarily we're interested in Customers and their Orders.   In a Graph, the data is modelled like so:
-- image::https://raw.githubusercontent.com/adam-cowley/northwind-neo4j/master/product-model.png[]

-- ### Popular Products
-- To find the most popular products in the dataset, we can follow the path from `:Customer` to `:Product`

match (p:people)-[l:LISTENS]->(m:Music)
return p.id, m.id, count(l) as listens
order by listens desc
limit 5;

MATCH (p1:people)-[x:Listens]->(s:music)<-[y:listens]-(p2:people)
WITH SUM(x.created_at * y.created_at) AS xyDotProduct,
 SQRT(x.created_at^2) AS xLength,
 SQRT(x.created_at^2) AS yLength,
 p1, p2
MERGE (p1)-[s:SIMILARITY]-(p2)
SET s.similarity = xyDotProduct / (xLength * yLength);
