//
//  VideoFeedController.swift
//  DouYinSwift5
//
//  Created by lym on 2020/7/23.
//  Copyright © 2020 lym. All rights reserved.
//

import UIKit

class VideoFeedController: BaseViewController {
    var tableView: UITableView!

    private let viewModel = VideoListViewModel()

    private var currentRow: Int = 0

    private lazy var commentListVC: CommentListViewController = {
        let vc = CommentListViewController()
        vc.onWillShow = { [weak self] in
            guard let `self` = self else { return }
            self.isShowComment = true
        }
        vc.onWillHide = { [weak self] in
            guard let `self` = self else { return }
            self.isShowComment = false
        }
        view.addSubview(vc.view)
        vc.view.frame = UIScreen.main.bounds
        return vc
    }()

    private var isShowComment: Bool = false {
        didSet {
            self.tabBarController?.tabBar.isHidden = isShowComment
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        viewModel.loadData { [weak self] in
            self?.tableView.reloadData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tabBarController?.tabBar.isHidden = isShowComment
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playCurrentRow()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        PlayerManager.shared.pauseAll()
    }

    private func setupUI() {
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.isPagingEnabled = true
        tableView.estimatedRowHeight = view.bounds.height
        tableView.showsVerticalScrollIndicator = false
        tableView.register(VideoFeedCell.self, forCellReuseIdentifier: "VideoFeedCell")
        view.addSubview(tableView)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -view.safeAreaInsets.bottom).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true

        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
    }

    private func playCurrentRow() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let cell = self.tableView.cellForRow(at: IndexPath(row: self.currentRow, section: 0)) as? VideoFeedCell else { return }
            if cell.isReadyToPlay {
                cell.play()
            } else {
                PlayerManager.shared.pauseAll()
                cell.startPlayOnReady = { [weak cell, weak self] in
                    guard let `self` = self, let cell = cell, let indexPath = self.tableView.indexPath(for: cell) else { return }
                    if self.currentRow == indexPath.row {
                        cell.play()
                    }
                }
            }
        }
    }
}

extension VideoFeedController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.list.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VideoFeedCell", for: indexPath) as! VideoFeedCell
        let cellViewModel = viewModel.list[indexPath.row]
        cell.bind(viewModel: cellViewModel)

        cell.onDidSelectCommentButton = { [weak self] _, _ in
            guard let `self` = self else { return }
            self.commentListVC.show()
        }
        return cell
    }
}

extension VideoFeedController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.frame.size.height
    }
}

extension VideoFeedController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let cell = tableView.visibleCells.first, let index = tableView.indexPath(for: cell) else { return }
        guard currentRow != index.row else { return }
        currentRow = index.row
        playCurrentRow()
    }
}
