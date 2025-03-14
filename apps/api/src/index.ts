import { createServer } from "./server";
import { consola } from "consola";

const port = process.env.PORT || 3001;
const server = createServer();

server.listen(port, () => {
  consola.info(`api running on ${port}`);
});
