import { app } from "./app.js";

const port = Number(process.env.PORT || 8080);
app.listen(port, () => {
  console.log(`NakilBakimAR API running on :${port}`);
});
