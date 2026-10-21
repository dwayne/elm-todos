import { Elm } from "./Main.elm";

function toData(json) {
  if (json) {
    try {
      return JSON.parse(json);
    } catch (e) {
      console.error("The JSON is corrupt", json, e);
    }
  }
  return null;
}

function main() {
  const key = "elm-todos-data";
  const json = localStorage.getItem(key);
  const data = toData(json);
  const app = Elm.Main.init({
    node: document.getElementById("app"),
    flags: data
  });

  app.ports.save.subscribe(function (data) {
    localStorage.setItem(key, JSON.stringify(data));
  });
}

main();
