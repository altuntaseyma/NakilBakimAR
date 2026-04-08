import "dotenv/config";
import cors from "cors";
import express from "express";
import { router } from "./routes/index.js";

export const app = express();
app.use(cors());
app.use(express.json());

app.get("/health", (_req, res) => res.json({ ok: true }));
app.use("/api", router);
