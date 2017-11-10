MATCH p = (root:Usuario {screenName: "beforeitsnews"})-[:INFECTA*1..]->(m)
WHERE NOT ()-[:INFECTA]->(root)
RETURN p, length(p) as L
ORDER BY L DESC
LIMIT 1