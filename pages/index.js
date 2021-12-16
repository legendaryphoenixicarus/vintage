
import React, { Component } from 'react';
import { useState, useEffect } from 'react'
import { ethers } from 'ethers'
import { useRouter } from 'next/router'
import Web3Modal from 'web3modal'
import Image from 'next/image'
import axios from "axios";

import { vintagetokenaddress, busdaddress } from '../config';
import VintageToken from '../artifacts/contracts/VintageToken.sol/VintageToken.json'
import BEP20Token from '../artifacts/contracts/BEP20Token.sol/BEP20Token.json'
// import { whitelists } from '../whitelist'
import BUSD from '../BUSD.json'

export default function Presale() {
    const [minting, setMinting] = useState(false);
    const [formInput, updateFormInput] = useState({ price: '', name: '', description: '' });
    const [wallet, updateWallet] =  useState("");
    const [busd, setBUSD] = useState("Buy X.XX VIT for X.XX BUSD");

    function updateVITAmount(e) {
        
        updateFormInput({ ...formInput, price: e.target.value });

        console.log( e.target.value );

        if (!isNaN(  e.target.value ))
        {
            const busdText = "Buy " +  e.target.value  + " VIT for " +  e.target.value  * 50 + " BUSD";
            setBUSD(busdText);
        } 
    }

    async function createNFTItem() {
        
        if (!formInput.price || isNaN(formInput.price))
        {
            alert("please input the valid VIT value.");
            return;
        }
        
        const web3Modal = new Web3Modal();
        const connection = await web3Modal.connect();
        const provider = new ethers.providers.Web3Provider(connection);
        const signer = provider.getSigner();
        const walletAddress = await signer.getAddress();
        
        updateWallet(walletAddress);
       
        let vintageTokenContract = new ethers.Contract(vintagetokenaddress, VintageToken.abi, signer);
        console.log(formInput.price);

        let price = formInput.price*50;
        
        const priceApprove = ethers.utils.parseUnits(price.toString(), 'ether');
        console.log(priceApprove);
        // console.log(BUSD)
        // const contractBUSD = new ethers.Contract(busdaddress, BUSD, signer)
        const contractBUSD = new ethers.Contract(busdaddress, BUSD.abi, signer);
        await contractBUSD.approve(vintagetokenaddress, priceApprove)
        
        try {
            const transaction = await vintageTokenContract.presale(formInput.price, busdaddress)
            let tx = await transaction.wait()
        } catch (error) {
            alert(error.data.message);
        }
    }
    
    useEffect(
        
        async () => {
            const web3Modal = new Web3Modal()
            const connection = await web3Modal.connect()
            const provider = new ethers.providers.Web3Provider(connection)
            const signer = provider.getSigner()
            const walletAddress = await signer.getAddress();
            updateWallet(walletAddress);
        }
    )

    
    return (
        <section className="author-area" >
            <div className="container">
                <div className="row justify-content-center inf-title">Vintage Token</div>
                <div className="row justify-content-center presale-title">Early Members Presale</div>
                <div className="row justify-content-center">
                    
                    <div className="col-12 col-md-6 col-lg-5 col-sm-8 offset-col-md-3">
                        
                        {/* Item Form */}
                        <form className="item-form card no-hover presale-form">
                            <div className="row presale-row">
                                <div className="col-12 inf-price">
                                    <img className="card-img-top presale-img" src="img/presale.png" alt=""/>
                                </div>
                                <div className="col-12 inf-price">
                                    1 VIT = 50 BUSD
                                </div>
                                <div className="col-12 presale-amount-text">
                                   Enter the amount of VIT you want to buy
                                </div>
                                <div className="col-12">
                                    <div className="form-group mt-3">
                                        <input type="text" className="presale-input" name="price" placeholder="X.XX VIT" required="required" onChange={updateVITAmount} />
                                    </div>
                                </div>
                                
                                <div className="col-12">

                                    {!minting && (
                                        <button className="btn-buy-inf w-100" type="button" onClick={createNFTItem}>{busd}</button>
                                    )}
                                    {minting && (
                                        // <span className="btn-buy-inf w-100 disabled" >{minting}</span>
                                        <span className="btn-buy-inf w-100 disabled" >{minting}</span>
                                    )}
                                    
                                </div>
                            </div>
                        </form>
                    </div>
                    
                </div>
            </div>
        </section>
    );
}

