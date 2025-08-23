CREATE CONSTRAINT entity_nid IF NOT EXISTS FOR (e:Entity) REQUIRE e.nid IS UNIQUE;

MERGE (c:Entity {nid:1})
  SET c.faLabel='مرکز همایش های پنسیلوانیا';

MERGE (p:Entity {nid:2})
  SET p.faLabel='فیلادلفیا';

MERGE (cl:Entity {nid:3})
  SET cl.faLabel='آب و هوای قاره‌ای مرطوب';

MERGE (c)-[:Relation {value:'قرار دارد در'}]->(p);
MERGE (p)-[:Relation {value:'آب و هوا'}]->(cl);
