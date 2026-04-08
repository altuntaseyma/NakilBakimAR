import { readFile } from "node:fs/promises";
import { pool } from "../db/pool.js";

const sql = await readFile(new URL("./001_init.sql", import.meta.url), "utf8");

try {
  await pool.query(sql);
  console.log("Migration complete.");
} finally {
  await pool.end();
}
