import React from 'react';
import Link from 'next/link'
import { useState } from 'react';
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
            {/* Navbar */}
            <nav data-aos="zoom-out" data-aos-delay={800} className="navbar navbar-expand">
                <div className="container header">
                    {/* Navbar Brand*/}
                    
                    <div className="ml-auto" />
                    {/* Navbar */}
                    <ul className="navbar-nav items mx-auto">
                        <li className="nav-item dropdown">
                            <Link href="/">
                                <a className="nav-link active" >Presale</a>
                            </Link>
                        </li>                       
                    </ul>
                    {/* Navbar Icons */}
                    <ul className="navbar-nav icons">
                        <li className="nav-item">
                            <a href="#" className="nav-link" data-toggle="modal" data-target="#search">
                                <i className="fas fa-search" />
                            </a>
                        </li>
                    </ul>
                    {/* Navbar Toggler */}
                    <ul className="navbar-nav toggle">
                        <li className="nav-item">
                            <a href="#" className="nav-link" data-toggle="modal" data-target="#menu">
                                <i className="fas fa-bars toggle-icon m-0" />
                            </a>
                        </li>
                    </ul>
                    {/* Navbar Action Button */}
                    <ul className="navbar-nav action">
                        <li className="nav-item ml-3">
                            {!address && (
                              <a className="btn ml-lg-auto text-white btn-bordered-white" onClick={_connectWallet}><i className="icon-wallet mr-md-2" />Wallet Connect</a>
                            )}
                            {address && (
                                <span className="btn ml-lg-auto btn-bordered-white"><i className="icon-wallet mr-md-2" />{address}</span>
                            )}
                        </li>
                    </ul>
                </div>
            </nav>
        </header>
    );
};

export default Header;