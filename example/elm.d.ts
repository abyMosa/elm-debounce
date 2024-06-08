declare module "*.elm" {
  export const Elm: any;
}

type Flags = {
  [key: string]: string | Array<string> | boolean | Flags
}
