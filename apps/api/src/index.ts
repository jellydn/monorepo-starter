import { consola } from "consola";
import { createServer } from "./server";

const port = process.env.PORT || 3001;
const server = createServer();

server.listen(port, () => {
	consola.info(`api running on ${port}`);
});
