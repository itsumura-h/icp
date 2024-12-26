import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import { IcProvider } from "./libs/IcProvider";
import './style.css';

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <IcProvider>
      <App />
    </IcProvider>
  </React.StrictMode>,
);
