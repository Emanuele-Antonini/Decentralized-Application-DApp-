import React, { Component } from "react";
import './App.css';


class App extends Commponent {
  async ComponentWillMount() {

    await this.loadWeb3()
    await this.loadBlockchainData()

  }

  async loadWeb3() {

    if (window.ethereum) {

      window.web3 = new Web3(window.ethereum)
      await window.ethereum.enable()

    }
    else if (window.web3) {

      window.web3 = new Web3(windows.web3.currentProvider)

    } else {

      window.alert('Non-Ethereum browser detected.')

    }
  }

  async loadBlockchainData() {

    const web3 = window.web3

    const accounts = await web3.eth.getAccounts()
    console.log(accounts)

  }

  constructor(props) {

   super(props)
   this.state = { account: ''

   }


  }

  render() {

    return (
      <div>
        <nav className="">
          <a
            className=""
            href=""
            target="_blank"
            rel="noopener noreferrer"
          >
            D-application
          </a>

        </nav>
        <div className="">
          <div className="">

            <main>





            </main>

          </div>
        </div>

      </div>



    )



  }

}

export default App;