MATCH (n:Noticia)-[:IMPACTA]->(u:Usuario)
RETURN n as Noticia, collect(u) as Usuarios, count(u) as CantUsuarios
