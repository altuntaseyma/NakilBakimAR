import { Router } from "express";
import { authRouter } from "./auth.js";
import { patientsRouter } from "./patients.js";
import { vitalsRouter } from "./vitals.js";
import { tasksRouter } from "./tasks.js";
import { arRouter } from "./ar.js";
import { notifyRouter } from "./notify.js";
import { scenariosRouter } from "./scenarios.js";

export const router = Router();
router.use("/auth", authRouter);
router.use("/patients", patientsRouter);
router.use("/vitals", vitalsRouter);
router.use("/tasks", tasksRouter);
router.use("/ar", arRouter);
router.use("/notify", notifyRouter);
router.use("/scenarios", scenariosRouter);
