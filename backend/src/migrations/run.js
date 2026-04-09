import { readdir, readFile } from "node:fs/promises";
import { pool } from "../db/pool.js";

try {
  const migrationsDir = new URL(".", import.meta.url);
  const files = (await readdir(migrationsDir))
    .filter((name) => name.endsWith(".sql"))
    .sort();

  for (const file of files) {
    const sql = await readFile(new URL(file, migrationsDir), "utf8");
    await pool.query(sql);
    console.log(`Applied migration: ${file}`);
  }
  console.log("Migration complete.");
} finally {
  await pool.end();
}
