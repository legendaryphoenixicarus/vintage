import React from 'react';
import Link from 'next/link'
import { useState } from 'react';
import Image from 'next/image'
import Web3Modal from 'web3modal'
import { ethers } from 'ethers'

const Header = () => {
    const [address, setAddress] = useState(null);
  
    async function _connectWallet() {
        const web3Modal = new Web3Modal()
        
        const connection = await web3Modal.connect()
        
        const provider = new ethers.providers.Web3Provider(connection)
        const signer = provider.getSigner();
        const wallet = await signer.getAddress();
        const tempwallet = wallet.slice(0,5) + "..." + wallet.slice(-3)
        setAddress(tempwallet)
    }

    return (
        <header id="header">
            <div className="navbar-custom">
                <ul className="netstorm-tab nav nav-tabs nav-tab-common" id="nav-tab">
                    <li>
                        <Link href="/">
                            <a className="active" id="nav-home-tab" data-toggle="pill" href="#nav-bond">
                                <h5 className="m-0">presale</h5>
                            </a>
                        </Link>
                    </li>
                    <li>
                        <Link href="/stake">
                            <a id="nav-profile-tab" data-toggle="pill" href="#nav-redeem">
                                <h5 className="m-0">Stake</h5>
                            </a>
                        </Link>
                    </li>
                    <li>
                        <Link href="/bond">
                            <a id="nav-home-tab" data-toggle="pill" href="#nav-bond">
                                <h5 className="m-0">Bond</h5>
                            </a>
                        </Link>
                    </li>
                </ul>
                <ul className="navbar-nav action">
                    <li className="nav-item ml-3">
                        {!address && (
                            <a className="btn ml-lg-auto btn-bordered-white" onClick={_connectWallet}><i className="icon-wallet mr-md-2" />Wallet Connect</a>
                        )}
                        {address && (
                            <span className="btn ml-lg-auto btn-bordered-white"><i className="icon-wallet mr-md-2" />{address}</span>
                        )}
                    </li>
                </ul>
            </div>
        </header>
    );
};

export default Header;