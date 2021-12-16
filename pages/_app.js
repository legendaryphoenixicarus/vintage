/* pages/_app.js */
import '../styles/globals.css'

import Header from '../src/components/Header/Header';
import Footer from '../src/components/Footer/Footer';
import ModalSearch from '../src/components/Modal/ModalSearch';
import ModalMenu from '../src/components/Modal/ModalMenu';
import Scrollup from '../src/components/Scrollup/Scrollup';

function MyApp({ Component, pageProps }) {
  return (
    <div className="main">
      <Header/>
      <Component {...pageProps} />
      
      <ModalSearch />
      {/* <ModalMenu /> */}
      <Scrollup />
    </div>
  )
}

export default MyApp
