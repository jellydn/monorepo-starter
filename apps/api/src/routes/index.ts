import { Router, type IRouter } from "express";
import authRoutes from "./auth";
import healthRoutes from "./health";
import messageRoutes from "./message";
import userRoutes from "./user";

const router: IRouter = Router();

// Mount routes
router.use("/", healthRoutes);
router.use("/message", messageRoutes);
router.use("/", authRoutes);
router.use("/", userRoutes);

export default router;