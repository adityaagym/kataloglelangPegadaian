import { RouterProvider } from "react-router";
import { Toaster } from "sonner";
import { router } from "./routes";

export default function App() {
  return (
    <>
      <Toaster position="top-center" expand={true} richColors />
      <RouterProvider router={router} />
    </>
  );
}
