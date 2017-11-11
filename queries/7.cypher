MATCH (root:Usuario)-[:INFECTA]->()
WHERE NOT ()-[:INFECTA]->(root)
WITH collect( distinct(root)) as rooters
MATCH (user:Usuario)
WHERE NOT user IN rooters
RETURN user;
